import 'dart:async';

import 'package:TaxiApp/src/core/models/active_ride_occupancy.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class RouteOccupancyProvider extends GetxController {
  RouteOccupancyProvider({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static RouteOccupancyProvider create() =>
      Get.isRegistered<RouteOccupancyProvider>()
      ? Get.find<RouteOccupancyProvider>()
      : Get.put<RouteOccupancyProvider>(RouteOccupancyProvider());

  static const occupancyLifetime = Duration(minutes: 15);
  static const heartbeatInterval = Duration(minutes: 5);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  final RxMap<int, int> occupiedSeatsByRoute = <int, int>{}.obs;
  final RxnString errorMessage = RxnString();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _occupancySubscription;
  Timer? _expiryTimer;
  List<ActiveRideOccupancy> _occupancies = const [];
  int? _activeRouteFeatureId;
  DateTime? _lastHeartbeatAt;
  String? _activeUserId;

  int occupiedSeats(int routeFeatureId) =>
      occupiedSeatsByRoute[routeFeatureId] ?? 0;

  @override
  void onInit() {
    super.onInit();
    _listenForOccupancy();
    _expiryTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _recomputeCounts(),
    );
    _authSubscription = _auth.userChanges().listen(_handleAuthChange);
    _handleAuthChange(_auth.currentUser);
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _occupancySubscription?.cancel();
    _expiryTimer?.cancel();
    super.onClose();
  }

  Future<void> enterRoute(TaxiRouteModel route) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    final now = DateTime.now();
    if (_activeRouteFeatureId == route.properties.fid &&
        _lastHeartbeatAt != null &&
        now.difference(_lastHeartbeatAt!) < heartbeatInterval) {
      return;
    }

    try {
      errorMessage.value = null;
      await _occupancyDocument(user.uid).set({
        'userId': user.uid,
        'routeFeatureId': route.properties.fid,
        'routeId': route.properties.route_id,
        'enteredAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(now.add(occupancyLifetime)),
      });
      _activeRouteFeatureId = route.properties.fid;
      _lastHeartbeatAt = now;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to enter route occupancy: $error\n$stackTrace');
      errorMessage.value = 'Unable to update taxi occupancy.';
    }
  }

  Future<void> leaveRoute() async {
    if (_activeRouteFeatureId == null) {
      return;
    }
    final user = _auth.currentUser;
    _activeRouteFeatureId = null;
    _lastHeartbeatAt = null;
    if (user == null) {
      return;
    }
    try {
      await _occupancyDocument(user.uid).delete();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to leave route occupancy: $error\n$stackTrace');
      errorMessage.value = 'Unable to update taxi occupancy.';
    }
  }

  void _listenForOccupancy() {
    _occupancySubscription = _firestore
        .collection('activeRideOccupancy')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .snapshots()
        .listen(
          (snapshot) {
            _occupancies = snapshot.docs
                .map(
                  (document) => ActiveRideOccupancy.fromJson(document.data()),
                )
                .toList(growable: false);
            _recomputeCounts();
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Unable to load route occupancy: $error\n$stackTrace');
            errorMessage.value = 'Unable to load taxi occupancy.';
          },
        );
  }

  void _recomputeCounts() {
    final now = DateTime.now();
    final counts = <int, int>{};
    for (final occupancy in _occupancies) {
      if (occupancy.isActiveAt(now)) {
        counts.update(
          occupancy.routeFeatureId,
          (currentCount) => currentCount + 1,
          ifAbsent: () => 1,
        );
      }
    }
    occupiedSeatsByRoute.assignAll(counts);
  }

  void _handleAuthChange(User? user) {
    if (_activeUserId == user?.uid) {
      return;
    }
    _activeUserId = user?.uid;
    _activeRouteFeatureId = null;
    _lastHeartbeatAt = null;
    if (user != null) {
      unawaited(_clearStaleOccupancy(user.uid));
    }
  }

  Future<void> _clearStaleOccupancy(String userId) async {
    try {
      await _occupancyDocument(userId).delete();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to clear stale occupancy: $error\n$stackTrace');
    }
  }

  DocumentReference<Map<String, dynamic>> _occupancyDocument(String userId) =>
      _firestore.collection('activeRideOccupancy').doc(userId);
}
