import 'package:TaxiApp/src/core/models/ride_request.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RideRequest parses persisted request details', () {
    final requestedAt = DateTime.utc(2026, 9, 14, 7, 5);
    final request = RideRequest.fromJson('request-1', {
      'riderId': 'rider-1',
      'riderName': 'Lerato',
      'routeFeatureId': 42,
      'routeId': 'route-42',
      'originName': 'Denneboom Temporary Taxi Rank',
      'destinationName': 'Silverlakes',
      'associationName': 'Mamelodi Amalgamated Taxi Association',
      'fare': 18,
      'pickupLocation': const GeoPoint(-25.7, 28.3),
      'status': 'requested',
      'requestedAt': Timestamp.fromDate(requestedAt),
      'expiredAt': null,
    });

    expect(request.id, 'request-1');
    expect(request.riderName, 'Lerato');
    expect(request.fare, 18);
    expect(request.pickupLocation.latitude, -25.7);
    expect(request.isRequested, isTrue);
    expect(
      request.bannerExpiresAt,
      Timestamp.fromDate(
        requestedAt,
      ).toDate().add(RideRequest.notificationDuration),
    );
  });

  test('RideRequest supports an unresolved server timestamp', () {
    final request = RideRequest.fromJson('request-pending', {
      'riderId': 'rider-1',
      'riderName': 'Lerato',
      'routeFeatureId': 42,
      'routeId': 'route-42',
      'originName': 'Denneboom Temporary Taxi Rank',
      'destinationName': 'Silverlakes',
      'associationName': 'Mamelodi Amalgamated Taxi Association',
      'fare': 18,
      'pickupLocation': const GeoPoint(-25.7, 28.3),
      'status': 'requested',
      'requestedAt': null,
      'expiredAt': null,
    });

    expect(request.requestedAt, isNull);
    expect(request.bannerExpiresAt, isNull);
  });

  test('RideRequest parses an expired request', () {
    final expiredAt = Timestamp.fromDate(DateTime.utc(2026, 9, 14, 8));
    final request = RideRequest.fromJson('request-expired', {
      'riderId': 'rider-1',
      'riderName': 'Lerato',
      'routeFeatureId': 42,
      'routeId': 'route-42',
      'originName': 'Denneboom Temporary Taxi Rank',
      'destinationName': 'Silverlakes',
      'associationName': 'Mamelodi Amalgamated Taxi Association',
      'fare': 18,
      'pickupLocation': const GeoPoint(-25.7, 28.3),
      'status': 'expired',
      'requestedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 14, 7, 5)),
      'expiredAt': expiredAt,
    });

    expect(request.isRequested, isFalse);
    expect(request.isExpired, isTrue);
    expect(request.expiredAt, expiredAt.toDate());
  });
}
