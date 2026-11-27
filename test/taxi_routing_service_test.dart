import 'dart:convert';
import 'dart:io';

import 'package:TaxiApp/src/core/models/destination_search_result.dart';
import 'package:TaxiApp/src/core/models/taxi_journey.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:TaxiApp/src/core/services/journey_progress_service.dart';
import 'package:TaxiApp/src/core/services/taxi_routing_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

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
    test(
      'keeps distinct journey options and skips duplicate corridors',
      () async {
        final fastest = _routeWithCoordinates(
          [
            [28.000, -25.000],
            [28.012, -25.000],
            [28.024, -25.000],
            [28.035, -25.000],
          ],
          id: 101,
          routeId: 'MAIN',
        );
        final duplicate = _routeWithCoordinates(
          [
            [28.000, -25.00002],
            [28.012, -25.00002],
            [28.024, -25.00002],
            [28.035, -25.00002],
          ],
          id: 102,
          routeId: 'DUPLICATE',
        );
        final north = _routeWithCoordinates(
          [
            [28.000, -25.000],
            [28.012, -24.996],
            [28.024, -24.996],
            [28.035, -25.000],
          ],
          id: 103,
          routeId: 'NORTH',
        );
        final south = _routeWithCoordinates(
          [
            [28.000, -25.000],
            [28.012, -25.005],
            [28.024, -25.005],
            [28.035, -25.000],
          ],
          id: 104,
          routeId: 'SOUTH',
        );
        const destination = DestinationSearchResult(
          label: 'Destination',
          subtitle: 'Pretoria',
          position: LatLng(-25, 28.035),
        );
        const origin = LatLng(-25, 28);
        const service = TaxiRoutingService();
        final routes = [duplicate, north, fastest, south];

        final options = await service.findJourneyOptionsAsync(
          origin: origin,
          destination: destination,
          routes: routes,
        );

        expect(options.map((option) => option.taxiLegs.single.route.id), [
          fastest.id,
          north.id,
          south.id,
        ]);
        expect(
          service
              .findBestJourney(
                origin: origin,
                destination: destination,
                routes: routes,
              )
              ?.taxiLegs
              .single
              .route
              .id,
          fastest.id,
        );
      },
    );

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
      expect(journey!.taxiLegs.single.route.id, route.id);
      expect(journey.steps.map((step) => step.type), [
        JourneyStepType.walk,
        JourneyStepType.taxi,
        JourneyStepType.walk,
      ]);
      expect(journey.taxiLegs.single.routePoints.first.longitude, 28.0);
      expect(journey.taxiLegs.single.routePoints.last.longitude, 28.03);
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

    test('builds a journey using only the explicitly selected route', () {
      final selectedRoute = _routeWithCoordinates(
        [
          [28.0000, -25.0000],
          [28.0100, -25.0000],
          [28.0200, -25.0000],
        ],
        id: 11,
        routeId: 'SELECTED',
      );
      final alternativeRoute = _routeWithCoordinates(
        [
          [28.0001, -25.0001],
          [28.0101, -25.0001],
          [28.0201, -25.0001],
        ],
        id: 12,
        routeId: 'ALTERNATIVE',
      );
      const destination = DestinationSearchResult(
        label: 'Selected route destination',
        subtitle: 'Pretoria',
        position: LatLng(-25.0000, 28.0200),
      );

      final unconstrainedJourney = const TaxiRoutingService().findBestJourney(
        origin: const LatLng(-25.0001, 28.0001),
        destination: destination,
        routes: [alternativeRoute, selectedRoute],
      );
      final selectedJourney = const TaxiRoutingService().findJourneyForRoute(
        origin: const LatLng(-25.0001, 28.0001),
        destination: destination,
        route: selectedRoute,
      );

      expect(unconstrainedJourney, isNotNull);
      expect(selectedJourney, isNotNull);
      expect(selectedJourney!.taxiLegs, hasLength(1));
      expect(selectedJourney.taxiLegs.single.route.id, selectedRoute.id);
      expect(
        selectedJourney.taxiLegs.single.route.id,
        isNot(alternativeRoute.id),
      );
    });

    test('rejects a selected route when it would require reverse travel', () {
      final selectedRoute = _routeWithCoordinates([
        [28.0000, -25.0000],
        [28.0100, -25.0000],
        [28.0200, -25.0000],
        [28.0300, -25.0000],
      ]);

      final journey =
          const TaxiRoutingService(
            maxBoardingWalkMeters: 500,
            maxFinalWalkMeters: 500,
          ).findJourneyForRoute(
            origin: const LatLng(-25.0001, 28.0301),
            destination: const DestinationSearchResult(
              label: 'Route origin',
              subtitle: 'Pretoria',
              position: LatLng(-25.0001, 28.0001),
            ),
            route: selectedRoute,
          );

      expect(journey, isNull);
    });

    test('builds a journey across two interlinking taxi routes', () {
      final firstRoute = _routeWithCoordinates(
        [
          [28.0000, -25.0000],
          [28.0100, -25.0000],
          [28.0200, -25.0000],
        ],
        id: 1,
        routeId: 'FIRST',
        destinationName: 'Transfer area',
      );
      final secondRoute = _routeWithCoordinates(
        [
          [28.0205, -25.0000],
          [28.0300, -25.0000],
          [28.0400, -25.0000],
        ],
        id: 2,
        routeId: 'SECOND',
        destinationName: 'Final rank',
      );
      const destination = DestinationSearchResult(
        label: 'Final destination',
        subtitle: 'Pretoria',
        position: LatLng(-25.0001, 28.0401),
      );

      final journey =
          const TaxiRoutingService(
            maxBoardingWalkMeters: 300,
            maxFinalWalkMeters: 300,
            maxTransferWalkMeters: 100,
          ).findBestJourney(
            origin: const LatLng(-25.0001, 28.0001),
            destination: destination,
            routes: [firstRoute, secondRoute],
          );

      expect(journey, isNotNull);
      expect(journey!.taxiLegs, hasLength(2));
      expect(journey.transferCount, 1);
      expect(
        journey.estimatedFare,
        firstRoute.properties.fare + secondRoute.properties.fare,
      );
      expect(journey.hasCompleteFareEstimate, isTrue);
      expect(journey.steps.map((step) => step.type), [
        JourneyStepType.walk,
        JourneyStepType.taxi,
        JourneyStepType.transfer,
        JourneyStepType.taxi,
        JourneyStepType.walk,
      ]);
    });

    test('plans journeys off the UI isolate', () async {
      final route = _routeWithCoordinates([
        [28.0000, -25.0000],
        [28.0100, -25.0000],
        [28.0200, -25.0000],
      ]);

      final journey = await const TaxiRoutingService().findBestJourneyAsync(
        origin: const LatLng(-25.0000, 28.0000),
        destination: const DestinationSearchResult(
          label: 'Destination',
          subtitle: 'Pretoria',
          position: LatLng(-25.0000, 28.0200),
        ),
        routes: [route],
      );

      expect(journey, isNotNull);
      expect(journey!.taxiLegs, hasLength(1));
    });
  });

  group('JourneyProgressService', () {
    test('advances steps and completes the journey near each endpoint', () {
      final route = _routeWithCoordinates([
        [28.0000, -25.0000],
        [28.0100, -25.0000],
        [28.0200, -25.0000],
      ]);
      const destination = DestinationSearchResult(
        label: 'Destination',
        subtitle: 'Pretoria',
        position: LatLng(-25.0000, 28.0200),
      );
      final journey = const TaxiRoutingService().findBestJourney(
        origin: const LatLng(-25.0000, 28.0000),
        destination: destination,
        routes: [route],
      )!;
      const service = JourneyProgressService();

      final boarded = service.update(
        journey: journey,
        currentStepIndex: 0,
        location: const LatLng(-25.0000, 28.0000),
      );
      final arrived = service.update(
        journey: journey,
        currentStepIndex: boarded.stepIndex,
        location: destination.position,
      );

      expect(boarded.stepIndex, 1);
      expect(boarded.isComplete, isFalse);
      expect(arrived.isComplete, isTrue);
      expect(arrived.stepIndex, journey.steps.length);
      expect(arrived.remainingDistanceMeters, 0);
      expect(arrived.remainingMinutes, 0);
    });

    test('counts the remaining part of a taxi leg and the full next leg', () {
      const origin = LatLng(0, 0);
      const corner = LatLng(0, 0.01);
      const dropOff = LatLng(0.01, 0.01);
      const end = LatLng(0.014, 0.01);
      const beforeCorner = LatLng(0, 0.004);
      final taxiMeters =
          TaxiRoutingService.distanceBetween(origin, corner) +
          TaxiRoutingService.distanceBetween(corner, dropOff);
      final walkMeters = TaxiRoutingService.distanceBetween(dropOff, end);
      final journey = TaxiJourney(
        origin: origin,
        destination: const DestinationSearchResult(
          label: 'Destination',
          subtitle: '',
          position: end,
        ),
        taxiLegs: [],
        steps: [
          JourneyStep(
            type: JourneyStepType.taxi,
            instruction: 'Take a taxi',
            detail: '',
            distanceMeters: taxiMeters,
            path: const [origin, corner, dropOff],
          ),
          JourneyStep(
            type: JourneyStepType.walk,
            instruction: 'Walk to the destination',
            detail: '',
            distanceMeters: walkMeters,
            path: const [dropOff, end],
            duration: const Duration(minutes: 8),
            hasMappedWalkingRoute: true,
          ),
        ],
      );
      const service = JourneyProgressService();
      final progress = service.update(
        journey: journey,
        currentStepIndex: 0,
        location: beforeCorner,
      );

      expect(progress.distanceToNextStepMeters, closeTo(taxiMeters * .8, 1));
      expect(
        progress.remainingDistanceMeters,
        closeTo(taxiMeters * .8 + walkMeters, 1),
      );
      expect(progress.remainingMinutes, 13);
      // Advance into the walking leg at the drop-off before measuring its ETA.
      final atDropOff = service.update(
        journey: journey,
        currentStepIndex: progress.stepIndex,
        location: dropOff,
      );
      final halfwayWalking = service.update(
        journey: journey,
        currentStepIndex: atDropOff.stepIndex,
        location: const LatLng(0.0121, 0.01),
      );
      expect(halfwayWalking.stepIndex, 1);
      expect(
        halfwayWalking.remainingDistanceMeters,
        closeTo(walkMeters * .475, 1),
      );
      expect(halfwayWalking.remainingMinutes, 4);
    });
  });
}

TaxiRouteModel _routeWithCoordinates(
  List<List<double>> coordinates, {
  int id = 999,
  String routeId = 'TEST',
  String destinationName = 'Test rank',
}) {
  final fixture =
      jsonDecode(File('example.json').readAsStringSync())
          as Map<String, dynamic>;
  final feature =
      Map<String, dynamic>.from(
          (fixture['features'] as List<dynamic>).first as Map<String, dynamic>,
        )
        ..['id'] = id
        ..['properties'] = {
          ...Map<String, dynamic>.from(
            ((fixture['features'] as List<dynamic>).first
                    as Map<String, dynamic>)['properties']
                as Map<String, dynamic>,
          ),
          'route_id': routeId,
          'destname': destinationName,
        }
        ..['geometry'] = {'type': 'LineString', 'coordinates': coordinates};
  return TaxiRouteModel.fromJson(feature);
}
