import 'package:TaxiApp/src/core/models/active_ride_occupancy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ActiveRideOccupancy expires stale riders', () {
    final now = DateTime.utc(2026, 9, 14, 8);
    final occupancy = ActiveRideOccupancy.fromJson({
      'userId': 'rider-1',
      'routeFeatureId': 42,
      'routeId': 'route-42',
      'enteredAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(minutes: 10))),
    });

    expect(occupancy.routeFeatureId, 42);
    expect(occupancy.isActiveAt(now), isTrue);
    expect(occupancy.isActiveAt(now.add(const Duration(minutes: 11))), isFalse);
  });

  test('ActiveRideOccupancy supports a pending server timestamp', () {
    final occupancy = ActiveRideOccupancy.fromJson({
      'userId': 'rider-1',
      'routeFeatureId': 42,
      'routeId': 'route-42',
      'enteredAt': null,
      'expiresAt': Timestamp.fromDate(DateTime.utc(2026, 9, 14, 8, 15)),
    });

    expect(occupancy.enteredAt, isNull);
  });
}
