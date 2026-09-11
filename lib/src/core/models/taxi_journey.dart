import 'package:TaxiApp/src/core/models/destination_search_result.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum JourneyStepType { walk, taxi }

class JourneyStep {
  const JourneyStep({
    required this.type,
    required this.instruction,
    required this.detail,
    required this.distanceMeters,
  });

  final JourneyStepType type;
  final String instruction;
  final String detail;
  final double distanceMeters;
}

class TaxiJourney {
  const TaxiJourney({
    required this.destination,
    required this.route,
    required this.boardingPoint,
    required this.exitPoint,
    required this.taxiRoutePoints,
    required this.walkToTaxiMeters,
    required this.taxiDistanceMeters,
    required this.walkToDestinationMeters,
    required this.steps,
  });

  final DestinationSearchResult destination;
  final TaxiRouteModel route;
  final LatLng boardingPoint;
  final LatLng exitPoint;
  final List<LatLng> taxiRoutePoints;
  final double walkToTaxiMeters;
  final double taxiDistanceMeters;
  final double walkToDestinationMeters;
  final List<JourneyStep> steps;

  double get totalDistanceMeters =>
      walkToTaxiMeters + taxiDistanceMeters + walkToDestinationMeters;
}
