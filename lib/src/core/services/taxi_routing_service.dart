import 'dart:math' as math;

import 'package:TaxiApp/src/core/models/destination_search_result.dart';
import 'package:TaxiApp/src/core/models/taxi_journey.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TaxiRoutingService {
  const TaxiRoutingService({
    this.maxBoardingWalkMeters = 5000,
    this.maxFinalWalkMeters = 5000,
    this.maxTransferWalkMeters = 350,
  });

  final double maxBoardingWalkMeters;
  final double maxFinalWalkMeters;
  final double maxTransferWalkMeters;

  Future<TaxiJourney?> findBestJourneyAsync({
    required LatLng origin,
    required DestinationSearchResult destination,
    required Iterable<TaxiRouteModel> routes,
  }) => compute(
    _findBestJourneyInBackground,
    _RoutingRequest(
      service: this,
      origin: origin,
      destination: destination,
      routes: routes.toList(growable: false),
    ),
  );

  TaxiJourney? findBestJourney({
    required LatLng origin,
    required DestinationSearchResult destination,
    required Iterable<TaxiRouteModel> routes,
  }) {
    final paths = _buildPaths(routes);
    final directJourney = _findBestDirectJourney(
      paths: paths,
      origin: origin,
      destination: destination.position,
    );
    final transferJourney = _findBestTransferJourney(
      paths: paths,
      origin: origin,
      destination: destination.position,
    );

    final bestJourney = switch ((directJourney, transferJourney)) {
      (null, null) => null,
      (final direct?, null) => direct,
      (null, final transfer?) => transfer,
      (final direct?, final transfer?) =>
        direct.score <= transfer.score ? direct : transfer,
    };

    return bestJourney?.toJourney(origin, destination);
  }

  List<_RoutePath> _buildPaths(Iterable<TaxiRouteModel> routes) => [
    for (final route in routes)
      for (
        var partIndex = 0;
        partIndex < route.geometry.parts.length;
        partIndex++
      )
        if (route.geometry.parts[partIndex].length >= 2)
          _RoutePath(
            route: route,
            partIndex: partIndex,
            points: route.geometry.parts[partIndex]
                .map((coordinate) => LatLng(coordinate[1], coordinate[0]))
                .toList(),
          ),
  ];

  _JourneyCandidate? _findBestDirectJourney({
    required List<_RoutePath> paths,
    required LatLng origin,
    required LatLng destination,
  }) {
    _JourneyCandidate? bestCandidate;

    for (final path in paths) {
      final metrics = _PathMetrics(
        path: path,
        origin: origin,
        destination: destination,
      );
      for (
        var boardingIndex = 0;
        boardingIndex < path.points.length - 1;
        boardingIndex++
      ) {
        final walkToTaxi = distanceBetween(origin, path.points[boardingIndex]);
        if (walkToTaxi > maxBoardingWalkMeters) {
          continue;
        }

        final exitIndex = metrics.destinationSuffixIndex[boardingIndex + 1];
        final walkToDestination =
            metrics.destinationSuffixDistance[boardingIndex + 1];
        final taxiDistance = metrics.pathDistance(boardingIndex, exitIndex);
        if (walkToDestination > maxFinalWalkMeters || taxiDistance < 250) {
          continue;
        }

        final candidate = _JourneyCandidate(
          legs: [
            metrics.toLeg(boardingIndex: boardingIndex, exitIndex: exitIndex),
          ],
          walkToTaxiMeters: walkToTaxi,
          transferWalkMeters: const [],
          walkToDestinationMeters: walkToDestination,
        );
        if (bestCandidate == null || candidate.score < bestCandidate.score) {
          bestCandidate = candidate;
        }
      }
    }
    return bestCandidate;
  }

  _JourneyCandidate? _findBestTransferJourney({
    required List<_RoutePath> paths,
    required LatLng origin,
    required LatLng destination,
  }) {
    final metrics = paths
        .map(
          (path) => _PathMetrics(
            path: path,
            origin: origin,
            destination: destination,
          ),
        )
        .toList();
    final originPaths = metrics
        .where(
          (item) => item.originPrefixDistance.last <= maxBoardingWalkMeters,
        )
        .toList();
    final destinationPaths = metrics
        .where(
          (item) => item.destinationSuffixDistance.first <= maxFinalWalkMeters,
        )
        .toList();

    if (originPaths.isEmpty || destinationPaths.isEmpty) {
      return null;
    }

    final transferIndex = _TransferSpatialIndex(
      cellSizeDegrees: maxTransferWalkMeters / 111000,
    );
    for (final destinationPath in destinationPaths) {
      for (
        var pointIndex = 0;
        pointIndex < destinationPath.path.points.length - 1;
        pointIndex++
      ) {
        transferIndex.add(
          _IndexedRoutePoint(metrics: destinationPath, pointIndex: pointIndex),
        );
      }
    }

    _JourneyCandidate? bestCandidate;
    for (final originPath in originPaths) {
      for (
        var firstExitIndex = 1;
        firstExitIndex < originPath.path.points.length;
        firstExitIndex++
      ) {
        final firstBoardingIndex =
            originPath.originPrefixIndex[firstExitIndex - 1];
        final walkToTaxi = originPath.originPrefixDistance[firstExitIndex - 1];
        final firstTaxiDistance = originPath.pathDistance(
          firstBoardingIndex,
          firstExitIndex,
        );
        if (walkToTaxi > maxBoardingWalkMeters || firstTaxiDistance < 250) {
          continue;
        }

        final firstExitPoint = originPath.path.points[firstExitIndex];
        for (final indexedPoint in transferIndex.near(firstExitPoint)) {
          final destinationPath = indexedPoint.metrics;
          if (destinationPath.path.route.id == originPath.path.route.id ||
              destinationPath.path.route.properties.route_id ==
                  originPath.path.route.properties.route_id) {
            continue;
          }

          final secondBoardingIndex = indexedPoint.pointIndex;
          final secondExitIndex =
              destinationPath.destinationSuffixIndex[secondBoardingIndex + 1];
          final transferDistance = distanceBetween(
            firstExitPoint,
            destinationPath.path.points[secondBoardingIndex],
          );
          final finalWalkDistance = destinationPath
              .destinationSuffixDistance[secondBoardingIndex + 1];
          final secondTaxiDistance = destinationPath.pathDistance(
            secondBoardingIndex,
            secondExitIndex,
          );
          if (transferDistance > maxTransferWalkMeters ||
              finalWalkDistance > maxFinalWalkMeters ||
              secondTaxiDistance < 250) {
            continue;
          }

          final candidate = _JourneyCandidate(
            legs: [
              originPath.toLeg(
                boardingIndex: firstBoardingIndex,
                exitIndex: firstExitIndex,
              ),
              destinationPath.toLeg(
                boardingIndex: secondBoardingIndex,
                exitIndex: secondExitIndex,
              ),
            ],
            walkToTaxiMeters: walkToTaxi,
            transferWalkMeters: [transferDistance],
            walkToDestinationMeters: finalWalkDistance,
          );
          if (bestCandidate == null || candidate.score < bestCandidate.score) {
            bestCandidate = candidate;
          }
        }
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

TaxiJourney? _findBestJourneyInBackground(_RoutingRequest request) =>
    request.service.findBestJourney(
      origin: request.origin,
      destination: request.destination,
      routes: request.routes,
    );

class _RoutingRequest {
  const _RoutingRequest({
    required this.service,
    required this.origin,
    required this.destination,
    required this.routes,
  });

  final TaxiRoutingService service;
  final LatLng origin;
  final DestinationSearchResult destination;
  final List<TaxiRouteModel> routes;
}

class _RoutePath {
  _RoutePath({
    required this.route,
    required this.partIndex,
    required this.points,
  }) : cumulativeDistance = _cumulativeDistance(points);

  final TaxiRouteModel route;
  final int partIndex;
  final List<LatLng> points;
  final List<double> cumulativeDistance;

  static List<double> _cumulativeDistance(List<LatLng> points) {
    final distances = List<double>.filled(points.length, 0);
    for (var index = 1; index < points.length; index++) {
      distances[index] =
          distances[index - 1] +
          TaxiRoutingService.distanceBetween(points[index - 1], points[index]);
    }
    return distances;
  }
}

class _PathMetrics {
  _PathMetrics({
    required this.path,
    required LatLng origin,
    required LatLng destination,
  }) : originPrefixIndex = List<int>.filled(path.points.length, 0),
       originPrefixDistance = List<double>.filled(
         path.points.length,
         double.infinity,
       ),
       destinationSuffixIndex = List<int>.filled(
         path.points.length,
         path.points.length - 1,
       ),
       destinationSuffixDistance = List<double>.filled(
         path.points.length,
         double.infinity,
       ) {
    var nearestOriginIndex = 0;
    var nearestOriginDistance = double.infinity;
    for (var index = 0; index < path.points.length; index++) {
      final distance = TaxiRoutingService.distanceBetween(
        origin,
        path.points[index],
      );
      if (distance < nearestOriginDistance) {
        nearestOriginDistance = distance;
        nearestOriginIndex = index;
      }
      originPrefixIndex[index] = nearestOriginIndex;
      originPrefixDistance[index] = nearestOriginDistance;
    }

    var nearestDestinationIndex = path.points.length - 1;
    var nearestDestinationDistance = double.infinity;
    for (var index = path.points.length - 1; index >= 0; index--) {
      final distance = TaxiRoutingService.distanceBetween(
        destination,
        path.points[index],
      );
      if (distance < nearestDestinationDistance) {
        nearestDestinationDistance = distance;
        nearestDestinationIndex = index;
      }
      destinationSuffixIndex[index] = nearestDestinationIndex;
      destinationSuffixDistance[index] = nearestDestinationDistance;
    }
  }

  final _RoutePath path;
  final List<int> originPrefixIndex;
  final List<double> originPrefixDistance;
  final List<int> destinationSuffixIndex;
  final List<double> destinationSuffixDistance;

  double pathDistance(int startIndex, int endIndex) =>
      path.cumulativeDistance[endIndex] - path.cumulativeDistance[startIndex];

  TaxiJourneyLeg toLeg({required int boardingIndex, required int exitIndex}) =>
      TaxiJourneyLeg(
        route: path.route,
        boardingPoint: path.points[boardingIndex],
        exitPoint: path.points[exitIndex],
        routePoints: path.points.sublist(boardingIndex, exitIndex + 1),
        distanceMeters: pathDistance(boardingIndex, exitIndex),
      );
}

class _IndexedRoutePoint {
  const _IndexedRoutePoint({required this.metrics, required this.pointIndex});

  final _PathMetrics metrics;
  final int pointIndex;
}

class _TransferSpatialIndex {
  _TransferSpatialIndex({required this.cellSizeDegrees});

  final double cellSizeDegrees;
  final Map<(int, int), List<_IndexedRoutePoint>> _cells = {};

  void add(_IndexedRoutePoint point) {
    final key = _cellFor(point.metrics.path.points[point.pointIndex]);
    _cells.putIfAbsent(key, () => []).add(point);
  }

  Iterable<_IndexedRoutePoint> near(LatLng point) sync* {
    final center = _cellFor(point);
    for (var latitudeOffset = -2; latitudeOffset <= 2; latitudeOffset++) {
      for (var longitudeOffset = -2; longitudeOffset <= 2; longitudeOffset++) {
        yield* _cells[(
              center.$1 + latitudeOffset,
              center.$2 + longitudeOffset,
            )] ??
            const [];
      }
    }
  }

  (int, int) _cellFor(LatLng point) => (
    (point.latitude / cellSizeDegrees).floor(),
    (point.longitude / cellSizeDegrees).floor(),
  );
}

class _JourneyCandidate {
  const _JourneyCandidate({
    required this.legs,
    required this.walkToTaxiMeters,
    required this.transferWalkMeters,
    required this.walkToDestinationMeters,
  });

  final List<TaxiJourneyLeg> legs;
  final double walkToTaxiMeters;
  final List<double> transferWalkMeters;
  final double walkToDestinationMeters;

  double get score =>
      walkToTaxiMeters * 1.25 +
      transferWalkMeters.fold(0, (total, distance) => total + distance * 2) +
      walkToDestinationMeters * 1.5 +
      legs.fold(0, (total, leg) => total + leg.distanceMeters * 0.05) +
      transferWalkMeters.length * 1500;

  TaxiJourney toJourney(LatLng origin, DestinationSearchResult destination) {
    final steps = <JourneyStep>[
      JourneyStep(
        type: JourneyStepType.walk,
        instruction:
            'Walk ${TaxiRoutingService.formatDistance(walkToTaxiMeters)}',
        detail:
            'Join the taxi route towards '
            '${legs.first.route.properties.destname.trim()}.',
        distanceMeters: walkToTaxiMeters,
        path: [origin, legs.first.boardingPoint],
      ),
    ];

    for (var index = 0; index < legs.length; index++) {
      final leg = legs[index];
      steps.add(
        JourneyStep(
          type: JourneyStepType.taxi,
          instruction:
              'Take a taxi towards ${leg.route.properties.destname.trim()}',
          detail:
              'Ride about '
              '${TaxiRoutingService.formatDistance(leg.distanceMeters)} '
              'on ${leg.route.properties.route_id}.',
          distanceMeters: leg.distanceMeters,
          path: leg.routePoints,
        ),
      );

      if (index < legs.length - 1) {
        final nextLeg = legs[index + 1];
        final transferDistance = transferWalkMeters[index];
        final transferName = _transferName(leg.route);
        steps.add(
          JourneyStep(
            type: JourneyStepType.transfer,
            instruction:
                'Transfer to a taxi towards '
                '${nextLeg.route.properties.destname.trim()}',
            detail: transferName == null
                ? 'Walk ${TaxiRoutingService.formatDistance(transferDistance)} '
                      'between the intersecting taxi routes and confirm the '
                      'transfer point with the driver.'
                : 'Walk ${TaxiRoutingService.formatDistance(transferDistance)} '
                      'near $transferName and confirm the transfer with the '
                      'driver.',
            distanceMeters: transferDistance,
            path: [leg.exitPoint, nextLeg.boardingPoint],
          ),
        );
      }
    }

    final lastLeg = legs.last;
    steps.add(
      JourneyStep(
        type: JourneyStepType.walk,
        instruction:
            'Walk '
            '${TaxiRoutingService.formatDistance(walkToDestinationMeters)}',
        detail: 'Continue from the taxi route to ${destination.label}.',
        distanceMeters: walkToDestinationMeters,
        path: [lastLeg.exitPoint, destination.position],
      ),
    );

    return TaxiJourney(
      origin: origin,
      destination: destination,
      taxiLegs: legs,
      steps: steps,
    );
  }

  String? _transferName(TaxiRouteModel route) {
    final transferPoint = route.properties.trnsferpnt.trim();
    if (transferPoint.isEmpty ||
        transferPoint.toLowerCase() == 'transfer' ||
        transferPoint == '80') {
      return null;
    }
    return transferPoint;
  }
}
