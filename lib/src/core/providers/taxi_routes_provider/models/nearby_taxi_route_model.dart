import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NearbyTaxiRouteModel {
  NearbyTaxiRouteModel({
    required this.routeId,
    required this.originPoint,
    required this.destinationPoint,
    required this.originName,
    required this.destinationName,
    required this.model,
  });

  final String routeId;
  final LatLng originPoint;
  final LatLng destinationPoint;
  final String originName;
  final String destinationName;
  final TaxiRouteModel model;
}
