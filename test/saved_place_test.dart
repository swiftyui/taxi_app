import 'package:TaxiApp/src/core/models/saved_place.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SavedPlace parses a Firestore location and destination', () {
    final updatedAt = DateTime.utc(2026, 9, 14, 9);
    final place = SavedPlace.fromJson('home', {
      'type': 'home',
      'label': 'Home',
      'address': 'Mamelodi, Pretoria',
      'location': const GeoPoint(-25.71, 28.34),
      'updatedAt': Timestamp.fromDate(updatedAt),
    });

    expect(place.type, SavedPlaceType.home);
    expect(place.position.latitude, -25.71);
    expect(place.destination.label, 'Home');
    expect(place.destination.subtitle, 'Mamelodi, Pretoria');
    expect(
      place.updatedAt?.millisecondsSinceEpoch,
      updatedAt.millisecondsSinceEpoch,
    );
  });

  test('SavedPlace safely treats unknown types as custom', () {
    final place = SavedPlace.fromJson('gym', {
      'type': 'regular',
      'label': 'Gym',
      'address': 'Pretoria',
      'location': const GeoPoint(-25.7, 28.2),
      'updatedAt': null,
    });

    expect(place.type, SavedPlaceType.custom);
    expect(place.updatedAt, isNull);
  });
}
