import 'dart:math' as math;

import 'package:TaxiApp/src/core/models/destination_search_result.dart';
import 'package:TaxiApp/src/core/models/taxi_journey.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TaxiRoutingService {
  const TaxiRoutingService({
    this.maxBoardingWalkMeters = 5000,
    this.maxFinalWalkMeters = 5000,
  });

  final double maxBoardingWalkMeters;
  final double maxFinalWalkMeters;

  TaxiJourney? findBestJourney({
    required LatLng origin,
    required DestinationSearchResult destination,
    required Iterable<TaxiRouteModel> routes,
  }) {
    _JourneyCandidate? bestCandidate;

    for (final route in routes) {
      for (final part in route.geometry.parts) {
        final points = part
            .where((coordinate) => coordinate.length >= 2)
            .map((coordinate) => LatLng(coordinate[1], coordinate[0]))
            .toList();
        if (points.length < 2) {
          continue;
        }

        final candidate = _findBestPartCandidate(
          route: route,
          points: points,
          origin: origin,
          destination: destination.position,
        );
        if (candidate == null) {
          continue;
        }

        if (bestCandidate == null || candidate.score < bestCandidate.score) {
          bestCandidate = candidate;
        }
      }
    }

    if (bestCandidate == null) {
      return null;
    }

    return bestCandidate.toJourney(destination);
  }

  _JourneyCandidate? _findBestPartCandidate({
    required TaxiRouteModel route,
    required List<LatLng> points,
    required LatLng origin,
    required LatLng destination,
  }) {
    final cumulativeDistance = List<double>.filled(points.length, 0);
    for (var index = 1; index < points.length; index++) {
      cumulativeDistance[index] =
          cumulativeDistance[index - 1] +
          distanceBetween(points[index - 1], points[index]);
    }

    final nearestExitFrom = List<int>.filled(points.length, points.length - 1);
    for (var index = points.length - 2; index >= 0; index--) {
      final nextBestIndex = nearestExitFrom[index + 1];
      nearestExitFrom[index] =
          distanceBetween(destination, points[index]) <
              distanceBetween(destination, points[nextBestIndex])
          ? index
          : nextBestIndex;
    }

    _JourneyCandidate? bestCandidate;
    for (
      var boardingIndex = 0;
      boardingIndex < points.length - 1;
      boardingIndex++
    ) {
      final walkToTaxi = distanceBetween(origin, points[boardingIndex]);
      if (walkToTaxi > maxBoardingWalkMeters) {
        continue;
      }

      final exitIndex = nearestExitFrom[boardingIndex + 1];
      final walkToDestination = distanceBetween(points[exitIndex], destination);
      final taxiDistance =
          cumulativeDistance[exitIndex] - cumulativeDistance[boardingIndex];
      if (walkToDestination > maxFinalWalkMeters || taxiDistance < 250) {
        continue;
      }

      final candidate = _JourneyCandidate(
        route: route,
        boardingPoint: points[boardingIndex],
        exitPoint: points[exitIndex],
        taxiRoutePoints: points.sublist(boardingIndex, exitIndex + 1),
        walkToTaxiMeters: walkToTaxi,
        taxiDistanceMeters: taxiDistance,
        walkToDestinationMeters: walkToDestination,
      );
      if (bestCandidate == null || candidate.score < bestCandidate.score) {
        bestCandidate = candidate;
      }
    }
    return bestCandidate;
  }

  static double distanceBetween(LatLng first, LatLng second) {
    const earthRadiusMeters = 6371000.0;
    final latitudeDelta = _toRadians(second.latitude - first.latitude);
    final longitudeDelta = _toRadians(second.longitude - first.longitude);
    final firstLatitude = _toRadians(first.latitude);
    final secondLatitude = _toRadians(second.latitude);
    final haversine =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(firstLatitude) *
            math.cos(secondLatitude) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    return earthRadiusMeters *
        2 *
        math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;

  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

class _JourneyCandidate {
  const _JourneyCandidate({
    required this.route,
    required this.boardingPoint,
    required this.exitPoint,
    required this.taxiRoutePoints,
    required this.walkToTaxiMeters,
    required this.taxiDistanceMeters,
    required this.walkToDestinationMeters,
  });

  final TaxiRouteModel route;
  final LatLng boardingPoint;
  final LatLng exitPoint;
  final List<LatLng> taxiRoutePoints;
  final double walkToTaxiMeters;
  final double taxiDistanceMeters;
  final double walkToDestinationMeters;

  double get score =>
      walkToTaxiMeters * 1.25 +
      walkToDestinationMeters * 1.5 +
      taxiDistanceMeters * 0.05;

  TaxiJourney toJourney(DestinationSearchResult destination) {
    final properties = route.properties;
    final boardingName = properties.originpnt.trim().isNotEmpty
        ? properties.originpnt.trim()
        : properties.originname.trim();
    final destinationName = properties.destname.trim().isNotEmpty
        ? properties.destname.trim()
        : 'the route destination';

    return TaxiJourney(
      destination: destination,
      route: route,
      boardingPoint: boardingPoint,
      exitPoint: exitPoint,
      taxiRoutePoints: taxiRoutePoints,
      walkToTaxiMeters: walkToTaxiMeters,
      taxiDistanceMeters: taxiDistanceMeters,
      walkToDestinationMeters: walkToDestinationMeters,
      steps: [
        JourneyStep(
          type: JourneyStepType.walk,
          instruction:
              'Walk ${TaxiRoutingService.formatDistance(walkToTaxiMeters)}',
          detail: 'Walk towards $boardingName to join the taxi route.',
          distanceMeters: walkToTaxiMeters,
        ),
        JourneyStep(
          type: JourneyStepType.taxi,
          instruction: 'Take a taxi towards $destinationName',
          detail:
              'Ride about ${TaxiRoutingService.formatDistance(taxiDistanceMeters)} '
              'on ${properties.route_id}.',
          distanceMeters: taxiDistanceMeters,
        ),
        JourneyStep(
          type: JourneyStepType.walk,
          instruction:
              'Walk ${TaxiRoutingService.formatDistance(walkToDestinationMeters)}',
          detail: 'Continue from the taxi route to ${destination.label}.',
          distanceMeters: walkToDestinationMeters,
        ),
      ],
    );
  }
}
