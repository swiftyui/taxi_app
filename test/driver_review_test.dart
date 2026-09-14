import 'package:TaxiApp/src/core/models/driver_review.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DriverReview parses a completed journey review', () {
    final updatedAt = Timestamp.fromDate(DateTime.utc(2026, 9, 14, 8));
    final review = DriverReview.fromJson('review-1', {
      'reviewerId': 'rider-1',
      'reviewerName': 'Lerato',
      'driverId': 'driver-1',
      'rating': 4,
      'comment': 'Friendly and safe driver.',
      'originName': 'Mamelodi',
      'destinationName': 'Pretoria CBD',
      'updatedAt': updatedAt,
    });

    expect(review.id, 'review-1');
    expect(review.driverId, 'driver-1');
    expect(review.rating, 4);
    expect(review.comment, 'Friendly and safe driver.');
    expect(review.updatedAt, updatedAt.toDate());
  });
}
