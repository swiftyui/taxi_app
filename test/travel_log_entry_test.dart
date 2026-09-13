import 'package:TaxiApp/src/core/models/travel_log_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TravelLogEntry', () {
    final startedAt = DateTime.utc(2026, 9, 13, 4, 30);
    const route = TravelLogRoute(
      featureId: 42,
      routeId: 'route-42',
      originName: 'Garsfontein',
      destinationName: 'Belle Ombre Taxi Rank',
      associationName: 'Menlyn Taxi Association',
      fare: 15,
    );

    test('round-trips through local and Firestore JSON', () {
      final entry = TravelLogEntry(
        id: 'journey-1',
        startedAt: startedAt,
        originName: 'Garsfontein',
        destinationName: 'Belle Ombre Taxi Rank',
        routes: const [route],
        status: TravelLogStatus.inProgress,
      );

      final decoded = TravelLogEntry.fromJson(entry.toJson());

      expect(decoded.id, entry.id);
      expect(decoded.startedAt, startedAt);
      expect(decoded.status, TravelLogStatus.inProgress);
      expect(decoded.routes.single.routeId, route.routeId);
      expect(decoded.routes.single.fare, 15);
    });

    test('marks an in-progress journey as completed', () {
      final completedAt = startedAt.add(const Duration(minutes: 35));
      final entry = TravelLogEntry(
        id: 'journey-2',
        startedAt: startedAt,
        originName: 'Garsfontein',
        destinationName: 'Belle Ombre Taxi Rank',
        routes: const [route],
        status: TravelLogStatus.inProgress,
      ).completed(completedAt);

      expect(entry.status, TravelLogStatus.completed);
      expect(entry.completedAt, completedAt);
    });
  });
}
