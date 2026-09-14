import 'dart:convert';

import 'package:TaxiApp/src/core/models/destination_search_result.dart';
import 'package:TaxiApp/src/core/models/taxi_journey.dart';
import 'package:TaxiApp/src/core/services/google_walking_directions_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

void main() {
  test('parses a Google walking route and encoded polyline', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/directions/v2:computeRoutes');
      expect(request.headers['X-Goog-Api-Key'], 'test-key');
      final requestBody = jsonDecode(request.body) as Map<String, dynamic>;
      expect(requestBody['travelMode'], 'WALK');
      return Response(
        jsonEncode({
          'routes': [
            {
              'distanceMeters': 1400,
              'duration': '1020s',
              'polyline': {'encodedPolyline': '_p~iF~ps|U_ulLnnqC_mqNvxq`@'},
            },
          ],
        }),
        200,
      );
    });
    final service = GoogleWalkingDirectionsService(
      client: client,
      apiKey: 'test-key',
    );

    final route = await service.walkingRoute(
      origin: const LatLng(38.5, -120.2),
      destination: const LatLng(43.252, -126.453),
    );

    expect(route.distanceMeters, 1400);
    expect(route.duration, const Duration(minutes: 17));
    expect(route.path, hasLength(3));
    expect(route.path.first.latitude, closeTo(38.5, 0.00001));
    expect(route.path.last.longitude, closeTo(-126.453, 0.00001));
  });

  test(
    'keeps an estimated connector when Google has no walking route',
    () async {
      final service = GoogleWalkingDirectionsService(
        client: MockClient((_) async => Response('{"routes":[]}', 200)),
        apiKey: 'test-key',
      );
      const journey = TaxiJourney(
        origin: LatLng(-25.7, 28.2),
        destination: DestinationSearchResult(
          label: 'Destination',
          subtitle: 'Pretoria',
          position: LatLng(-25.71, 28.21),
        ),
        taxiLegs: [],
        steps: [
          JourneyStep(
            type: JourneyStepType.walk,
            instruction: 'Walk 1.4 km',
            detail: 'Join the taxi route.',
            distanceMeters: 1400,
            path: [LatLng(-25.7, 28.2), LatLng(-25.71, 28.21)],
          ),
        ],
      );

      final enriched = await service.enrichJourney(journey);

      expect(enriched.steps.single.hasMappedWalkingRoute, isFalse);
      expect(enriched.steps.single.distanceMeters, 1400);
      expect(enriched.steps.single.path, hasLength(2));
    },
  );
}
