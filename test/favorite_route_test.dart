import 'package:TaxiApp/src/core/models/favorite_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FavoriteRoute parses a persisted route snapshot', () {
    final addedAt = DateTime.utc(2026, 9, 14, 8, 30);
    final favorite = FavoriteRoute.fromJson({
      'featureId': -42,
      'routeId': 'driver:user-1:route-1',
      'originName': 'Mamelodi',
      'destinationName': 'Pretoria CBD',
      'associationName': 'HambaGo Taxi Association',
      'fare': 24,
      'addedAt': Timestamp.fromDate(addedAt),
    });

    expect(favorite.featureId, -42);
    expect(favorite.documentId, '-42');
    expect(favorite.routeId, 'driver:user-1:route-1');
    expect(favorite.fare, 24);
    expect(
      favorite.addedAt?.millisecondsSinceEpoch,
      addedAt.millisecondsSinceEpoch,
    );
  });

  test('FavoriteRoute supports a pending server timestamp', () {
    final favorite = FavoriteRoute.fromJson({
      'featureId': 42,
      'routeId': 'route-42',
      'originName': 'Mamelodi',
      'destinationName': 'Pretoria CBD',
      'associationName': 'Taxi Association',
      'fare': 18.5,
      'addedAt': null,
    });

    expect(favorite.addedAt, isNull);
    expect(favorite.documentId, '42');
  });
}
