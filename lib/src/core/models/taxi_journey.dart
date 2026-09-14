import 'package:TaxiApp/src/core/models/destination_search_result.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum JourneyStepType { walk, taxi, transfer }

class JourneyStep {
  const JourneyStep({
    required this.type,
    required this.instruction,
    required this.detail,
    required this.distanceMeters,
    required this.path,
    this.duration,
    this.hasMappedWalkingRoute = false,
  });

  final JourneyStepType type;
  final String instruction;
  final String detail;
  final double distanceMeters;
  final List<LatLng> path;
  final Duration? duration;
  final bool hasMappedWalkingRoute;

  LatLng get destination => path.last;

  JourneyStep withWalkingRoute({
    required List<LatLng> path,
    required double distanceMeters,
    required Duration duration,
    required String instruction,
    required String detail,
  }) => JourneyStep(
    type: type,
    instruction: instruction,
    detail: detail,
    distanceMeters: distanceMeters,
    path: path,
    duration: duration,
    hasMappedWalkingRoute: true,
  );
}

class TaxiJourneyLeg {
  const TaxiJourneyLeg({
    required this.route,
    required this.boardingPoint,
    required this.exitPoint,
    required this.routePoints,
    required this.distanceMeters,
  });

  final TaxiRouteModel route;
  final LatLng boardingPoint;
  final LatLng exitPoint;
  final List<LatLng> routePoints;
  final double distanceMeters;
}

class TaxiJourney {
  const TaxiJourney({
    required this.origin,
    required this.destination,
    required this.taxiLegs,
    required this.steps,
  });

  final LatLng origin;
  final DestinationSearchResult destination;
  final List<TaxiJourneyLeg> taxiLegs;
  final List<JourneyStep> steps;

  int get transferCount => taxiLegs.length - 1;

  double get totalDistanceMeters =>
      steps.fold(0, (total, step) => total + step.distanceMeters);

  List<double> get listedFares => taxiLegs
      .map((leg) => leg.route.properties.fare)
      .where((fare) => fare > 0)
      .toList(growable: false);

  double get estimatedFare =>
      listedFares.fold(0, (total, fare) => total + fare);

  bool get hasCompleteFareEstimate =>
      taxiLegs.isNotEmpty &&
      taxiLegs.every((leg) => leg.route.properties.fare > 0);

  Iterable<JourneyStep> get pedestrianSteps => steps.where(
    (step) =>
        step.type == JourneyStepType.walk ||
        step.type == JourneyStepType.transfer,
  );

  TaxiJourney withSteps(List<JourneyStep> updatedSteps) => TaxiJourney(
    origin: origin,
    destination: destination,
    taxiLegs: taxiLegs,
    steps: updatedSteps,
  );
}
