import 'package:cloud_firestore/cloud_firestore.dart';

class DriverReview {
  const DriverReview({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    required this.driverId,
    required this.rating,
    required this.comment,
    required this.originName,
    required this.destinationName,
    required this.updatedAt,
  });

  factory DriverReview.fromJson(String id, Map<String, dynamic> json) =>
      DriverReview(
        id: id,
        reviewerId: json['reviewerId'] as String,
        reviewerName: json['reviewerName'] as String,
        driverId: json['driverId'] as String,
        rating: (json['rating'] as num).toDouble(),
        comment: json['comment'] as String? ?? '',
        originName: json['originName'] as String,
        destinationName: json['destinationName'] as String,
        updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      );

  final String id;
  final String reviewerId;
  final String reviewerName;
  final String driverId;
  final double rating;
  final String comment;
  final String originName;
  final String destinationName;
  final DateTime? updatedAt;
}

class DriverReviewPrompt {
  const DriverReviewPrompt({
    required this.reviewId,
    required this.driverId,
    required this.routeDocumentId,
    required this.journeyId,
    required this.originName,
    required this.destinationName,
    required this.driverLabel,
  });

  final String reviewId;
  final String driverId;
  final String routeDocumentId;
  final String journeyId;
  final String originName;
  final String destinationName;
  final String driverLabel;
}
