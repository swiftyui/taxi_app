import 'dart:async';

import 'package:TaxiApp/src/core/models/driver_profile.dart';
import 'package:TaxiApp/src/core/models/driver_review.dart';
import 'package:TaxiApp/src/core/models/taxi_journey.dart';
import 'package:TaxiApp/src/core/providers/driver_account_provider/driver_account_provider.dart';
import 'package:TaxiApp/src/core/providers/hamba_points_provider/hamba_points_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class DriverReviewsProvider extends GetxController {
  DriverReviewsProvider({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    DriverAccountProvider? driverAccountProvider,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _driverAccountProvider =
           driverAccountProvider ?? DriverAccountProvider.create();

  static DriverReviewsProvider create() =>
      Get.isRegistered<DriverReviewsProvider>()
      ? Get.find<DriverReviewsProvider>()
      : Get.put<DriverReviewsProvider>(DriverReviewsProvider());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final DriverAccountProvider _driverAccountProvider;

  final RxList<DriverReview> reviews = <DriverReview>[].obs;
  final Rxn<DriverReviewPrompt> activePrompt = Rxn<DriverReviewPrompt>();
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool lastReviewAwardedPoint = false.obs;
  final RxnString errorMessage = RxnString();

  final List<DriverReviewPrompt> _promptQueue = [];
  final Set<String> _queuedReviewIds = {};
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _reviewsSubscription;
  Worker? _driverWorker;

  double get averageRating => reviews.isEmpty
      ? 0
      : reviews.fold<double>(0, (total, review) => total + review.rating) /
            reviews.length;

  @override
  void onInit() {
    super.onInit();
    _authSubscription = _auth.userChanges().listen(
      (_) => unawaited(_syncDriverReviews()),
    );
    _driverWorker = ever<DriverProfile?>(
      _driverAccountProvider.profile,
      (_) => unawaited(_syncDriverReviews()),
    );
    unawaited(_syncDriverReviews());
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _reviewsSubscription?.cancel();
    _driverWorker?.dispose();
    super.onClose();
  }

  Future<void> queueJourneyReviews({
    required TaxiJourney journey,
    required String journeyId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    final seenDrivers = <String>{};
    for (final leg in journey.taxiLegs) {
      final routeIdentity = _driverRouteIdentity(leg.route.properties.route_id);
      if (routeIdentity == null ||
          routeIdentity.driverId == user.uid ||
          !seenDrivers.add(routeIdentity.driverId)) {
        continue;
      }
      final reviewId =
          '${user.uid}_${journeyId}_${routeIdentity.routeDocumentId}';
      if (!_queuedReviewIds.add(reviewId)) {
        continue;
      }
      try {
        final existingReview = await _reviews(
          routeIdentity.driverId,
        ).doc(reviewId).get();
        if (existingReview.exists) {
          continue;
        }
        _promptQueue.add(
          DriverReviewPrompt(
            reviewId: reviewId,
            driverId: routeIdentity.driverId,
            routeDocumentId: routeIdentity.routeDocumentId,
            journeyId: journeyId,
            originName: leg.route.properties.originname,
            destinationName: leg.route.properties.destname,
            driverLabel: leg.route.properties.assocname,
          ),
        );
      } on FirebaseException catch (error, stackTrace) {
        debugPrint(
          'Unable to check existing driver review: $error\n$stackTrace',
        );
      }
    }
    _showNextPrompt();
  }

  Future<bool> submitReview({
    required DriverReviewPrompt prompt,
    required double rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      errorMessage.value = 'Sign in to rate your driver.';
      return false;
    }
    if (rating < 1 || rating > 5) {
      errorMessage.value = 'Choose a rating from 1 to 5 stars.';
      return false;
    }

    try {
      isSubmitting.value = true;
      errorMessage.value = null;
      lastReviewAwardedPoint.value = false;
      final reviewReference = _reviews(prompt.driverId).doc(prompt.reviewId);
      final awardReference = _firestore
          .collection('users')
          .doc(prompt.driverId)
          .collection('hambaPointAwards')
          .doc('driver_review_${prompt.reviewId}');
      final awardedPoint = await _firestore.runTransaction((transaction) async {
        final existingReview = await transaction.get(reviewReference);
        if (existingReview.exists) {
          return false;
        }
        transaction.set(reviewReference, {
          'reviewerId': user.uid,
          'reviewerName': _reviewerName(user),
          'driverId': prompt.driverId,
          'routeDocumentId': prompt.routeDocumentId,
          'journeyId': prompt.journeyId,
          'rating': rating,
          'comment': comment.trim(),
          'originName': prompt.originName,
          'destinationName': prompt.destinationName,
          'driverLabel': prompt.driverLabel,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (rating >= 3) {
          transaction.set(awardReference, {
            'type': 'driverReview',
            'driverId': prompt.driverId,
            'reviewerId': user.uid,
            'reviewId': prompt.reviewId,
            'points': 1,
            'awardedAt': FieldValue.serverTimestamp(),
          });
          return true;
        }
        return false;
      });
      lastReviewAwardedPoint.value = awardedPoint;
      return true;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to save driver review: $error\n$stackTrace');
      errorMessage.value = error.message ?? 'Unable to save this review.';
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  void completePrompt() {
    activePrompt.value = null;
    _showNextPrompt();
  }

  Future<void> _syncDriverReviews() async {
    await _reviewsSubscription?.cancel();
    _reviewsSubscription = null;
    reviews.clear();
    final user = _auth.currentUser;
    if (user == null || !_driverAccountProvider.isDriver) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    _reviewsSubscription = _reviews(user.uid).snapshots().listen(
      (snapshot) {
        final updatedReviews =
            snapshot.docs
                .map(
                  (document) =>
                      DriverReview.fromJson(document.id, document.data()),
                )
                .toList(growable: false)
              ..sort(
                (left, right) =>
                    (right.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                        .compareTo(
                          left.updatedAt ??
                              DateTime.fromMillisecondsSinceEpoch(0),
                        ),
              );
        reviews.assignAll(updatedReviews);
        isLoading.value = false;
        if (updatedReviews.isNotEmpty) {
          unawaited(HambaPointsProvider.create().reloadPoints());
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Unable to load driver reviews: $error\n$stackTrace');
        errorMessage.value = 'Unable to load your driver reviews.';
        isLoading.value = false;
      },
    );
  }

  void _showNextPrompt() {
    if (activePrompt.value == null && _promptQueue.isNotEmpty) {
      activePrompt.value = _promptQueue.removeAt(0);
    }
  }

  CollectionReference<Map<String, dynamic>> _reviews(String driverId) =>
      _firestore
          .collection('driverReviews')
          .doc(driverId)
          .collection('reviews');

  String _reviewerName(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    return 'HambaGo traveller';
  }

  _DriverRouteIdentity? _driverRouteIdentity(String routeId) {
    final parts = routeId.split(':');
    if (parts.length != 3 || parts.first != 'driver') {
      return null;
    }
    return _DriverRouteIdentity(driverId: parts[1], routeDocumentId: parts[2]);
  }
}

class _DriverRouteIdentity {
  const _DriverRouteIdentity({
    required this.driverId,
    required this.routeDocumentId,
  });

  final String driverId;
  final String routeDocumentId;
}
