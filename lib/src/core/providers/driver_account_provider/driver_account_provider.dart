import 'dart:async';

import 'package:TaxiApp/src/core/models/driver_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';

class DriverAccountProvider extends GetxController {
  DriverAccountProvider({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    Geocoding? geocoding,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _geocoding = geocoding ?? Geocoding();

  static DriverAccountProvider create() =>
      Get.isRegistered<DriverAccountProvider>()
      ? Get.find<DriverAccountProvider>()
      : Get.put<DriverAccountProvider>(DriverAccountProvider());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Geocoding _geocoding;

  final Rxn<DriverProfile> profile = Rxn<DriverProfile>();
  final RxList<DriverRoute> routes = <DriverRoute>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxnString errorMessage = RxnString();
  final RxnString successMessage = RxnString();

  StreamSubscription<User?>? _authSubscription;

  bool get isDriver => profile.value != null;

  @override
  void onInit() {
    super.onInit();
    _authSubscription = _auth.userChanges().listen((user) {
      if (user == null) {
        profile.value = null;
        routes.clear();
      } else {
        unawaited(loadDriverAccount());
      }
    });
    if (_auth.currentUser != null) {
      unawaited(loadDriverAccount());
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  Future<void> loadDriverAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;
      final profileDocument = await _profileDocument(user.uid).get();
      profile.value = profileDocument.exists
          ? DriverProfile.fromJson(profileDocument.data()!)
          : null;
      if (profile.value == null) {
        routes.clear();
        return;
      }
      final routeSnapshot = await _routesCollection(
        user.uid,
      ).orderBy('createdAt', descending: true).get();
      routes.assignAll(
        routeSnapshot.docs.map(
          (document) => DriverRoute.fromJson(document.id, document.data()),
        ),
      );
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to load driver account: $error\n$stackTrace');
      errorMessage.value = 'Unable to load your driver account.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveDriverProfile(DriverProfile driverProfile) async {
    final user = _auth.currentUser;
    if (user == null) {
      errorMessage.value = 'Sign in before creating a driver account.';
      return false;
    }

    try {
      isSaving.value = true;
      errorMessage.value = null;
      successMessage.value = null;
      await _profileDocument(user.uid).set(driverProfile.toJson());
      await loadDriverAccount();
      successMessage.value = 'Your driver and taxi details have been saved.';
      return true;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to save driver profile: $error\n$stackTrace');
      errorMessage.value = error.message ?? 'Unable to save driver details.';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> createRoute({
    required String originName,
    required String destinationName,
    required double fare,
    required List<String> serviceDays,
    required String notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null || profile.value == null) {
      errorMessage.value =
          'Complete your driver account before creating routes.';
      return false;
    }

    try {
      isSaving.value = true;
      errorMessage.value = null;
      successMessage.value = null;
      final locations = await Future.wait([
        _geocoding.locationFromAddress('$originName, South Africa'),
        _geocoding.locationFromAddress('$destinationName, South Africa'),
      ]);
      if (locations.any((result) => result.isEmpty)) {
        errorMessage.value =
            'We could not locate the route origin or destination.';
        return false;
      }
      final origin = locations[0].first;
      final destination = locations[1].first;
      await _routesCollection(user.uid).add({
        'driverId': user.uid,
        'originName': originName.trim(),
        'destinationName': destinationName.trim(),
        'origin': GeoPoint(origin.latitude, origin.longitude),
        'destination': GeoPoint(destination.latitude, destination.longitude),
        'fare': fare,
        'serviceDays': serviceDays,
        'notes': notes.trim(),
        'status': 'pendingReview',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await loadDriverAccount();
      successMessage.value =
          'Route submitted. It will appear publicly after review.';
      return true;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to create driver route: $error\n$stackTrace');
      errorMessage.value = error.message ?? 'Unable to create this route.';
      return false;
    } catch (error, stackTrace) {
      debugPrint('Unable to geocode driver route: $error\n$stackTrace');
      errorMessage.value =
          'Unable to validate these locations. Check your connection.';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  DocumentReference<Map<String, dynamic>> _profileDocument(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('driverAccount')
          .doc('profile');

  CollectionReference<Map<String, dynamic>> _routesCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('driverRoutes');
}
