import 'dart:async';

import 'package:TaxiApp/src/core/models/driver_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    required String departureTime,
    required String notes,
    LatLng? originPosition,
    LatLng? destinationPosition,
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
      final resolvedOrigin =
          originPosition ?? await _geocodeAddress(originName);
      final resolvedDestination =
          destinationPosition ?? await _geocodeAddress(destinationName);
      if (resolvedOrigin == null || resolvedDestination == null) {
        errorMessage.value =
            'We could not locate the route origin or destination.';
        return false;
      }
      await _routesCollection(user.uid).add({
        'driverId': user.uid,
        'originName': originName.trim(),
        'destinationName': destinationName.trim(),
        'origin': GeoPoint(resolvedOrigin.latitude, resolvedOrigin.longitude),
        'destination': GeoPoint(
          resolvedDestination.latitude,
          resolvedDestination.longitude,
        ),
        'fare': fare,
        'serviceDays': serviceDays,
        'departureTime': departureTime,
        'notes': notes.trim(),
        'associationName': profile.value!.associationName,
        'seatCapacity': profile.value!.seatCapacity,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await loadDriverAccount();
      successMessage.value = 'Route added to your active routes.';
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

  Future<bool> updateRoute({
    required String routeId,
    required String originName,
    required String destinationName,
    required double fare,
    required List<String> serviceDays,
    required String departureTime,
    required String notes,
    LatLng? originPosition,
    LatLng? destinationPosition,
  }) async {
    final user = _auth.currentUser;
    final driverProfile = profile.value;
    if (user == null || driverProfile == null) {
      errorMessage.value = 'Your driver account is not available.';
      return false;
    }

    try {
      isSaving.value = true;
      errorMessage.value = null;
      successMessage.value = null;
      final resolvedOrigin =
          originPosition ?? await _geocodeAddress(originName);
      final resolvedDestination =
          destinationPosition ?? await _geocodeAddress(destinationName);
      if (resolvedOrigin == null || resolvedDestination == null) {
        errorMessage.value =
            'We could not locate the route origin or destination.';
        return false;
      }
      await _routesCollection(user.uid).doc(routeId).update({
        'originName': originName.trim(),
        'destinationName': destinationName.trim(),
        'origin': GeoPoint(resolvedOrigin.latitude, resolvedOrigin.longitude),
        'destination': GeoPoint(
          resolvedDestination.latitude,
          resolvedDestination.longitude,
        ),
        'fare': fare,
        'serviceDays': serviceDays,
        'departureTime': departureTime,
        'notes': notes.trim(),
        'associationName': driverProfile.associationName,
        'seatCapacity': driverProfile.seatCapacity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await loadDriverAccount();
      successMessage.value = 'Route updated.';
      return true;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to update driver route: $error\n$stackTrace');
      errorMessage.value = error.message ?? 'Unable to update this route.';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteRoute(String routeId) async {
    final user = _auth.currentUser;
    if (user == null) {
      errorMessage.value = 'Your driver account is not available.';
      return false;
    }

    try {
      isSaving.value = true;
      errorMessage.value = null;
      successMessage.value = null;
      await _routesCollection(user.uid).doc(routeId).delete();
      routes.removeWhere((route) => route.id == routeId);
      successMessage.value = 'Route deleted.';
      return true;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to delete driver route: $error\n$stackTrace');
      errorMessage.value = error.message ?? 'Unable to delete this route.';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    final locations = await _geocoding.locationFromAddress(
      '${address.trim()}, South Africa',
    );
    if (locations.isEmpty) {
      return null;
    }
    return LatLng(locations.first.latitude, locations.first.longitude);
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
