import 'dart:async';

import 'package:TaxiApp/src/core/models/driver_profile.dart';
import 'package:TaxiApp/src/core/models/ride_request.dart';
import 'package:TaxiApp/src/core/providers/driver_account_provider/driver_account_provider.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/nearby_taxi_route_model.dart';
import 'package:TaxiApp/src/core/providers/user_location_provider/user_location_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class RideRequestsProvider extends GetxController {
  RideRequestsProvider({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    DriverAccountProvider? driverAccountProvider,
    UserLocationProvider? userLocationProvider,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _driverAccountProvider =
           driverAccountProvider ?? DriverAccountProvider.create(),
       _userLocationProvider =
           userLocationProvider ?? UserLocationProvider.create();

  static RideRequestsProvider create() =>
      Get.isRegistered<RideRequestsProvider>()
      ? Get.find<RideRequestsProvider>()
      : Get.put<RideRequestsProvider>(RideRequestsProvider());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final DriverAccountProvider _driverAccountProvider;
  final UserLocationProvider _userLocationProvider;

  final RxList<RideRequest> driverRequests = <RideRequest>[].obs;
  final RxList<RideRequest> myRequests = <RideRequest>[].obs;
  final Rxn<RideRequest> bannerRequest = Rxn<RideRequest>();
  final RxDouble bannerProgress = 0.0.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isLoadingRequests = false.obs;
  final RxBool isLoadingMyRequests = false.obs;
  final RxnString errorMessage = RxnString();

  final Set<String> _seenBannerIds = {};
  final List<RideRequest> _bannerQueue = [];
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _driverRequestsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _myRequestsSubscription;
  Worker? _driverWorker;
  Timer? _bannerTimer;

  bool get isSignedIn => _auth.currentUser != null;
  bool get isDriver => _driverAccountProvider.isDriver;

  @override
  void onInit() {
    super.onInit();
    _authSubscription = _auth.userChanges().listen((_) {
      unawaited(_syncMyRequests());
      unawaited(_syncDriverRequests());
    });
    _driverWorker = ever<DriverProfile?>(
      _driverAccountProvider.profile,
      (_) => unawaited(_syncDriverRequests()),
    );
    unawaited(_syncMyRequests());
    unawaited(_syncDriverRequests());
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _driverRequestsSubscription?.cancel();
    _myRequestsSubscription?.cancel();
    _driverWorker?.dispose();
    _bannerTimer?.cancel();
    super.onClose();
  }

  Future<bool> requestRide(NearbyTaxiRouteModel route) async {
    final user = _auth.currentUser;
    if (user == null) {
      errorMessage.value = 'Sign in before requesting a ride.';
      return false;
    }

    try {
      isSubmitting.value = true;
      errorMessage.value = null;
      final position =
          _userLocationProvider.userLocation.value ??
          await _userLocationProvider.refreshLocation(requestPermission: true);
      if (position == null) {
        errorMessage.value =
            _userLocationProvider.errorMessage.value ??
            'Your pickup location is required to request a ride.';
        return false;
      }

      await _firestore.collection('rideRequests').add({
        'riderId': user.uid,
        'riderName': _riderName(user),
        'routeFeatureId': route.model.properties.fid,
        'routeId': route.routeId,
        'originName': route.originName,
        'destinationName': route.destinationName,
        'associationName': route.model.properties.assocname,
        'fare': route.model.properties.fare,
        'pickupLocation': GeoPoint(position.latitude, position.longitude),
        'status': 'requested',
        'requestedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to request a ride: $error\n$stackTrace');
      errorMessage.value = error.message ?? 'Unable to request this ride.';
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  void dismissBanner() {
    _bannerTimer?.cancel();
    _bannerTimer = null;
    bannerRequest.value = null;
    bannerProgress.value = 0;
    _showNextBanner();
  }

  Future<void> refreshDriverRequests() async {
    if (_auth.currentUser == null || !_driverAccountProvider.isDriver) {
      return;
    }
    try {
      isLoadingRequests.value = true;
      errorMessage.value = null;
      final snapshot = await _firestore
          .collection('rideRequests')
          .orderBy('requestedAt', descending: true)
          .limit(100)
          .get();
      _handleRequestSnapshot(snapshot);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to refresh ride requests: $error\n$stackTrace');
      errorMessage.value = 'Unable to refresh ride requests.';
      isLoadingRequests.value = false;
    }
  }

  Future<void> refreshMyRequests() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    try {
      isLoadingMyRequests.value = true;
      errorMessage.value = null;
      final snapshot = await _firestore
          .collection('rideRequests')
          .where('riderId', isEqualTo: user.uid)
          .get();
      _handleMyRequestSnapshot(snapshot);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to refresh your ride requests: $error\n$stackTrace');
      errorMessage.value = 'Unable to refresh your ride requests.';
      isLoadingMyRequests.value = false;
    }
  }

  Future<bool> expireRequest(String requestId) async {
    try {
      errorMessage.value = null;
      await _firestore.collection('rideRequests').doc(requestId).update({
        'status': 'expired',
        'expiredAt': FieldValue.serverTimestamp(),
      });
      return true;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to expire ride request: $error\n$stackTrace');
      errorMessage.value = error.message ?? 'Unable to expire this request.';
      return false;
    }
  }

  Future<bool> deleteRequest(String requestId) async {
    try {
      errorMessage.value = null;
      await _firestore.collection('rideRequests').doc(requestId).delete();
      return true;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to delete ride request: $error\n$stackTrace');
      errorMessage.value = error.message ?? 'Unable to delete this request.';
      return false;
    }
  }

  Future<void> _syncMyRequests() async {
    await _myRequestsSubscription?.cancel();
    _myRequestsSubscription = null;
    myRequests.clear();
    final user = _auth.currentUser;
    if (user == null) {
      isLoadingMyRequests.value = false;
      return;
    }
    isLoadingMyRequests.value = true;
    _myRequestsSubscription = _firestore
        .collection('rideRequests')
        .where('riderId', isEqualTo: user.uid)
        .snapshots()
        .listen(
          _handleMyRequestSnapshot,
          onError: (Object error, StackTrace stackTrace) {
            debugPrint(
              'Unable to listen for your ride requests: $error\n$stackTrace',
            );
            errorMessage.value = 'Unable to load your ride requests.';
            isLoadingMyRequests.value = false;
          },
        );
  }

  void _handleMyRequestSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final requests =
        snapshot.docs
            .map(
              (document) => RideRequest.fromJson(document.id, document.data()),
            )
            .toList(growable: false)
          ..sort((left, right) {
            final leftTime =
                left.requestedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final rightTime =
                right.requestedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return rightTime.compareTo(leftTime);
          });
    myRequests.assignAll(requests);
    isLoadingMyRequests.value = false;
  }

  Future<void> _syncDriverRequests() async {
    await _driverRequestsSubscription?.cancel();
    _driverRequestsSubscription = null;
    _bannerTimer?.cancel();
    bannerRequest.value = null;
    bannerProgress.value = 0;
    driverRequests.clear();
    _bannerQueue.clear();
    _seenBannerIds.clear();

    if (_auth.currentUser == null || !_driverAccountProvider.isDriver) {
      isLoadingRequests.value = false;
      return;
    }

    isLoadingRequests.value = true;
    _driverRequestsSubscription = _firestore
        .collection('rideRequests')
        .orderBy('requestedAt', descending: true)
        .limit(100)
        .snapshots()
        .listen(
          _handleRequestSnapshot,
          onError: (Object error, StackTrace stackTrace) {
            debugPrint(
              'Unable to listen for ride requests: $error\n$stackTrace',
            );
            errorMessage.value = 'Unable to load ride requests.';
            isLoadingRequests.value = false;
          },
        );
  }

  void _handleRequestSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final requests = snapshot.docs
        .map((document) => RideRequest.fromJson(document.id, document.data()))
        .where(
          (request) =>
              request.isRequested && request.riderId != _auth.currentUser?.uid,
        )
        .toList(growable: false);
    driverRequests.assignAll(requests);
    isLoadingRequests.value = false;
    final activeRequestIds = requests.map((request) => request.id).toSet();
    _bannerQueue.removeWhere(
      (request) => !activeRequestIds.contains(request.id),
    );
    final activeBanner = bannerRequest.value;
    if (activeBanner != null && !activeRequestIds.contains(activeBanner.id)) {
      dismissBanner();
    }

    final now = DateTime.now();
    for (final request in requests.reversed) {
      final bannerExpiresAt = request.bannerExpiresAt;
      if (request.riderId == _auth.currentUser?.uid ||
          bannerExpiresAt == null ||
          !bannerExpiresAt.isAfter(now) ||
          !_seenBannerIds.add(request.id)) {
        continue;
      }
      _bannerQueue.add(request);
    }
    _showNextBanner();
  }

  void _showNextBanner() {
    if (bannerRequest.value != null || _bannerQueue.isEmpty) {
      return;
    }
    final now = DateTime.now();
    while (_bannerQueue.isNotEmpty) {
      final request = _bannerQueue.removeAt(0);
      final bannerExpiresAt = request.bannerExpiresAt;
      if (bannerExpiresAt == null || !bannerExpiresAt.isAfter(now)) {
        continue;
      }
      bannerRequest.value = request;
      unawaited(SystemSound.play(SystemSoundType.alert));
      _updateBannerProgress();
      _bannerTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _updateBannerProgress(),
      );
      return;
    }
  }

  void _updateBannerProgress() {
    final request = bannerRequest.value;
    if (request == null) {
      return;
    }
    final bannerExpiresAt = request.bannerExpiresAt;
    if (bannerExpiresAt == null) {
      dismissBanner();
      return;
    }
    final remaining = bannerExpiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      dismissBanner();
      return;
    }
    bannerProgress.value =
        remaining.inMilliseconds /
        RideRequest.notificationDuration.inMilliseconds;
  }

  String _riderName(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'HambaGo rider';
  }
}
