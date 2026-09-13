import 'package:TaxiApp/src/core/providers/hamba_points_provider/hamba_points_provider.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class RouteReview {
  const RouteReview({
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.updatedAt,
  });

  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime? updatedAt;
}

class RouteRatingSummary {
  const RouteRatingSummary({
    required this.average,
    required this.reviewCount,
    this.userRating,
    this.userComment,
    this.reviews = const [],
  });

  static const empty = RouteRatingSummary(average: 0, reviewCount: 0);

  final double average;
  final int reviewCount;
  final double? userRating;
  final String? userComment;
  final List<RouteReview> reviews;
}

class RouteReviewsProvider extends GetxController {
  RouteReviewsProvider({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static RouteReviewsProvider create() =>
      Get.isRegistered<RouteReviewsProvider>()
      ? Get.find<RouteReviewsProvider>()
      : Get.put<RouteReviewsProvider>(RouteReviewsProvider());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  final RxMap<int, RouteRatingSummary> summaries =
      <int, RouteRatingSummary>{}.obs;
  final RxSet<int> loadingRouteIds = <int>{}.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool lastReviewEarnedPoint = false.obs;
  final RxnString errorMessage = RxnString();

  Future<void> loadSummary(TaxiRouteModel route) async {
    final featureId = route.properties.fid;
    if (loadingRouteIds.contains(featureId)) {
      return;
    }
    loadingRouteIds.add(featureId);
    try {
      final snapshot = await _reviews(route).get();
      var total = 0.0;
      double? userRating;
      String? userComment;
      final reviews = <RouteReview>[];
      for (final document in snapshot.docs) {
        final data = document.data();
        final rating = (data['rating'] as num).toDouble();
        total += rating;
        reviews.add(
          RouteReview(
            userId: document.id,
            userName: data['userName'] as String? ?? 'HambaGo traveller',
            rating: rating,
            comment: data['comment'] as String? ?? '',
            updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
          ),
        );
        if (document.id == _auth.currentUser?.uid) {
          userRating = rating;
          userComment = data['comment'] as String?;
        }
      }
      reviews.sort(
        (left, right) =>
            (right.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(
                  left.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                ),
      );
      summaries[featureId] = RouteRatingSummary(
        average: snapshot.docs.isEmpty ? 0 : total / snapshot.docs.length,
        reviewCount: snapshot.docs.length,
        userRating: userRating,
        userComment: userComment,
        reviews: reviews,
      );
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to load route reviews: $error\n$stackTrace');
      errorMessage.value = 'Unable to load route ratings.';
    } finally {
      loadingRouteIds.remove(featureId);
    }
  }

  Future<bool> submitReview({
    required TaxiRouteModel route,
    required double rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      errorMessage.value = 'Sign in to leave a route review.';
      return false;
    }
    if (rating < 1 || rating > 5) {
      errorMessage.value = 'Choose a rating from 1 to 5 stars.';
      return false;
    }

    try {
      isSubmitting.value = true;
      errorMessage.value = null;
      lastReviewEarnedPoint.value = false;
      final reviewReference = _reviews(route).doc(user.uid);
      final awardReference = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('hambaPointAwards')
          .doc('review_${route.properties.fid}');
      final awardedPoint = await _firestore.runTransaction((transaction) async {
        final existingAward = await transaction.get(awardReference);
        transaction.set(reviewReference, {
          'userId': user.uid,
          'userName': user.displayName ?? 'HambaGo traveller',
          'rating': rating,
          'comment': comment.trim(),
          'routeId': route.properties.route_id,
          'featureId': route.properties.fid,
          'originName': route.properties.originname,
          'destinationName': route.properties.destname,
          'associationName': route.properties.assocname,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (!existingAward.exists) {
          transaction.set(awardReference, {
            'type': 'routeReview',
            'featureId': route.properties.fid,
            'points': 1,
            'awardedAt': FieldValue.serverTimestamp(),
          });
          return true;
        }
        return false;
      });
      lastReviewEarnedPoint.value = awardedPoint;
      if (awardedPoint) {
        await HambaPointsProvider.create().reloadPoints();
      }
      await loadSummary(route);
      return true;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to save route review: $error\n$stackTrace');
      errorMessage.value = error.message ?? 'Unable to save your review.';
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  CollectionReference<Map<String, dynamic>> _reviews(TaxiRouteModel route) =>
      _firestore
          .collection('routeReviews')
          .doc('${route.properties.fid}')
          .collection('reviews');
}
