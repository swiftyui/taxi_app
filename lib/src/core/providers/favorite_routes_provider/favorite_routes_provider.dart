import 'dart:async';

import 'package:TaxiApp/src/core/models/favorite_route.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/nearby_taxi_route_model.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/taxi_routes_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class FavoriteRoutesProvider extends GetxController {
  FavoriteRoutesProvider({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    TaxiRoutesProvider? taxiRoutesProvider,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _taxiRoutesProvider = taxiRoutesProvider ?? TaxiRoutesProvider.create();

  static FavoriteRoutesProvider create() =>
      Get.isRegistered<FavoriteRoutesProvider>()
      ? Get.find<FavoriteRoutesProvider>()
      : Get.put<FavoriteRoutesProvider>(FavoriteRoutesProvider());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final TaxiRoutesProvider _taxiRoutesProvider;

  final RxList<FavoriteRoute> favorites = <FavoriteRoute>[].obs;
  final Rxn<User> user = Rxn<User>();
  final RxSet<int> updatingRouteIds = <int>{}.obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _favoritesSubscription;

  bool get isSignedIn => user.value != null;

  @override
  void onInit() {
    super.onInit();
    user.value = _auth.currentUser;
    _authSubscription = _auth.userChanges().listen((currentUser) {
      user.value = currentUser;
      unawaited(_subscribeToFavorites());
    });
    unawaited(_subscribeToFavorites());
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _favoritesSubscription?.cancel();
    super.onClose();
  }

  bool isFavorite(int featureId) =>
      favorites.any((favorite) => favorite.featureId == featureId);

  NearbyTaxiRouteModel? resolveRoute(FavoriteRoute favorite) {
    for (final route in _taxiRoutesProvider.taxiRoutes) {
      if (route.id == favorite.featureId) {
        return NearbyTaxiRouteModel.fromTaxiRouteModel(route);
      }
    }
    return null;
  }

  Future<bool> toggle(NearbyTaxiRouteModel route) async {
    final user = _auth.currentUser;
    if (user == null) {
      errorMessage.value = 'Sign in to save your favourite routes.';
      return false;
    }

    final featureId = route.model.id;
    if (updatingRouteIds.contains(featureId)) {
      return false;
    }

    try {
      updatingRouteIds.add(featureId);
      errorMessage.value = null;
      final favorite = FavoriteRoute.fromRoute(route);
      final reference = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favoriteRoutes')
          .doc(favorite.documentId);
      if (isFavorite(featureId)) {
        await _deleteReference(reference);
      } else {
        await reference.set(favorite.toJson());
      }
      return true;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to update favourite route: $error\n$stackTrace');
      errorMessage.value =
          error.message ?? 'Unable to update this favourite route.';
      return false;
    } finally {
      updatingRouteIds.remove(featureId);
    }
  }

  Future<bool> remove(FavoriteRoute favorite) async {
    final user = _auth.currentUser;
    if (user == null || updatingRouteIds.contains(favorite.featureId)) {
      return false;
    }
    try {
      updatingRouteIds.add(favorite.featureId);
      errorMessage.value = null;
      await _deleteReference(
        _firestore
            .collection('users')
            .doc(user.uid)
            .collection('favoriteRoutes')
            .doc(favorite.documentId),
      );
      return true;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to remove favourite route: $error\n$stackTrace');
      errorMessage.value =
          error.message ?? 'Unable to remove this favourite route.';
      return false;
    } finally {
      updatingRouteIds.remove(favorite.featureId);
    }
  }

  Future<void> _deleteReference(
    DocumentReference<Map<String, dynamic>> reference,
  ) => reference.delete();

  Future<void> _subscribeToFavorites() async {
    await _favoritesSubscription?.cancel();
    _favoritesSubscription = null;
    favorites.clear();
    errorMessage.value = null;

    final user = _auth.currentUser;
    if (user == null) {
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    _favoritesSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favoriteRoutes')
        .snapshots()
        .listen(
          (snapshot) {
            final entries =
                snapshot.docs
                    .map((document) => FavoriteRoute.fromJson(document.data()))
                    .toList()
                  ..sort(
                    (left, right) => (right.addedAt ?? DateTime(0)).compareTo(
                      left.addedAt ?? DateTime(0),
                    ),
                  );
            favorites.assignAll(entries);
            isLoading.value = false;
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Unable to load favourite routes: $error\n$stackTrace');
            errorMessage.value = 'Unable to load your favourite routes.';
            isLoading.value = false;
          },
        );
  }
}
