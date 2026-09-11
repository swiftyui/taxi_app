import 'dart:convert';
import 'dart:io';

import 'package:TaxiApp/src/core/models/destination_search_result.dart';
import 'package:TaxiApp/src/core/models/taxi_journey.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:TaxiApp/src/core/services/taxi_routing_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('TaxiRouteGeometry', () {
    test('parses LineString coordinates in longitude-latitude order', () {
      final geometry = TaxiRouteGeometry.fromJson({
        'type': 'LineString',
        'coordinates': [
          [28.0, -25.0],
          ['28.1', '-25.1'],
        ],
      });

      expect(geometry.parts, hasLength(1));
      expect(geometry.coordinates, [
        [28.0, -25.0],
        [28.1, -25.1],
      ]);
    });

    test('normalizes all MultiLineString parts without joining them', () {
      final geometry = TaxiRouteGeometry.fromJson({
        'type': 'MultiLineString',
        'coordinates': [
          [
            [28.0, -25.0],
            [28.1, -25.1],
          ],
          [
            [28.2, -25.2],
            [28.3, -25.3],
          ],
        ],
      });

      expect(geometry.parts, hasLength(2));
      expect(geometry.parts.first, [
        [28.0, -25.0],
        [28.1, -25.1],
      ]);
      expect(geometry.coordinates, hasLength(4));
    });
  });

  group('TaxiRoutingService', () {
    test('builds walking, directional taxi, and final walking steps', () {
      final route = _routeWithCoordinates([
        [28.0000, -25.0000],
        [28.0100, -25.0000],
        [28.0200, -25.0000],
        [28.0300, -25.0000],
      ]);
      const destination = DestinationSearchResult(
        label: 'Test destination',
        subtitle: 'Pretoria',
        position: LatLng(-25.0002, 28.0302),
      );

      final journey = const TaxiRoutingService().findBestJourney(
        origin: const LatLng(-25.0001, 28.0001),
        destination: destination,
        routes: [route],
      );

      expect(journey, isNotNull);
      expect(journey!.route.id, route.id);
      expect(journey.steps.map((step) => step.type), [
        JourneyStepType.walk,
        JourneyStepType.taxi,
        JourneyStepType.walk,
      ]);
      expect(journey.taxiRoutePoints.first.longitude, 28.0);
      expect(journey.taxiRoutePoints.last.longitude, 28.03);
    });

    test('does not route backwards along directional geometry', () {
      final route = _routeWithCoordinates([
        [28.0000, -25.0000],
        [28.0100, -25.0000],
        [28.0200, -25.0000],
        [28.0300, -25.0000],
      ]);
      const destination = DestinationSearchResult(
        label: 'Behind the user',
        subtitle: 'Pretoria',
        position: LatLng(-25.0001, 28.0001),
      );

      final journey =
          const TaxiRoutingService(
            maxBoardingWalkMeters: 500,
            maxFinalWalkMeters: 500,
          ).findBestJourney(
            origin: const LatLng(-25.0001, 28.0301),
            destination: destination,
            routes: [route],
          );

      expect(journey, isNull);
    });
  });
}

TaxiRouteModel _routeWithCoordinates(List<List<double>> coordinates) {
  final fixture =
      jsonDecode(File('example.json').readAsStringSync())
          as Map<String, dynamic>;
  final feature =
      Map<String, dynamic>.from(
          (fixture['features'] as List<dynamic>).first as Map<String, dynamic>,
        )
        ..['id'] = 999
        ..['geometry'] = {'type': 'LineString', 'coordinates': coordinates};
  return TaxiRouteModel.fromJson(feature);
}
