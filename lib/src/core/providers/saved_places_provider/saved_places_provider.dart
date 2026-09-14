import 'dart:async';

import 'package:TaxiApp/src/core/models/saved_place.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SavedPlacesProvider extends GetxController {
  SavedPlacesProvider({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static SavedPlacesProvider create() => Get.isRegistered<SavedPlacesProvider>()
      ? Get.find<SavedPlacesProvider>()
      : Get.put<SavedPlacesProvider>(SavedPlacesProvider());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  final RxList<SavedPlace> places = <SavedPlace>[].obs;
  final Rxn<User> user = Rxn<User>();
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxnString errorMessage = RxnString();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  bool get isSignedIn => user.value != null;

  @override
  void onInit() {
    super.onInit();
    user.value = _auth.currentUser;
    _authSubscription = _auth.userChanges().listen((currentUser) {
      user.value = currentUser;
      unawaited(_subscribe());
    });
    unawaited(_subscribe());
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _subscription?.cancel();
    super.onClose();
  }

  Future<bool> save({
    required SavedPlaceType type,
    required String label,
    required String address,
    required LatLng position,
    String? id,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      errorMessage.value = 'Sign in to save places.';
      return false;
    }
    final normalizedLabel = label.trim();
    final normalizedAddress = address.trim();
    if (normalizedLabel.length < 2 || normalizedLabel.length > 60) {
      errorMessage.value = 'Enter a place name between 2 and 60 characters.';
      return false;
    }

    try {
      isSaving.value = true;
      errorMessage.value = null;
      final isReservedId =
          id == SavedPlaceType.home.name || id == SavedPlaceType.work.name;
      final documentId = type == SavedPlaceType.custom
          ? (id != null && !isReservedId
                ? id
                : DateTime.now().microsecondsSinceEpoch.toString())
          : type.name;
      final batch = _firestore.batch();
      batch.set(_places(user.uid).doc(documentId), {
        'type': type.name,
        'label': normalizedLabel,
        'address': normalizedAddress,
        'location': GeoPoint(position.latitude, position.longitude),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (id != null && id != documentId) {
        batch.delete(_places(user.uid).doc(id));
      }
      await batch.commit();
      return true;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to save place: $error\n$stackTrace');
      errorMessage.value = error.message ?? 'Unable to save this place.';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> delete(SavedPlace place) async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    try {
      errorMessage.value = null;
      await _places(user.uid).doc(place.id).delete();
      return true;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to delete saved place: $error\n$stackTrace');
      errorMessage.value = error.message ?? 'Unable to delete this place.';
      return false;
    }
  }

  CollectionReference<Map<String, dynamic>> _places(String userId) =>
      _firestore.collection('users').doc(userId).collection('savedPlaces');

  Future<void> _subscribe() async {
    await _subscription?.cancel();
    _subscription = null;
    places.clear();
    errorMessage.value = null;
    final user = _auth.currentUser;
    if (user == null) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    _subscription = _places(user.uid).snapshots().listen(
      (snapshot) {
        final updatedPlaces =
            snapshot.docs
                .map(
                  (document) =>
                      SavedPlace.fromJson(document.id, document.data()),
                )
                .toList()
              ..sort((left, right) {
                final typeComparison = left.type.index.compareTo(
                  right.type.index,
                );
                return typeComparison != 0
                    ? typeComparison
                    : left.label.compareTo(right.label);
              });
        places.assignAll(updatedPlaces);
        isLoading.value = false;
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Unable to load saved places: $error\n$stackTrace');
        errorMessage.value = 'Unable to load your saved places.';
        isLoading.value = false;
      },
    );
  }
}
