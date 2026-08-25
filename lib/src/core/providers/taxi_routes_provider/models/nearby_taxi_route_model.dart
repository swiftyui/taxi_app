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

  factory NearbyTaxiRouteModel.fromTaxiRouteModel(TaxiRouteModel model) {
    final originPoint = LatLng(
      model.geometry.coordinates[0][1],
      model.geometry.coordinates[0][0],
    );
    final destinationPoint = LatLng(
      model.geometry.coordinates.last[1],
      model.geometry.coordinates.last[0],
    );

    return NearbyTaxiRouteModel(
      routeId: model.properties.route_id,
      originPoint: originPoint,
      destinationPoint: destinationPoint,
      originName: model.properties.originname,
      destinationName: model.properties.destname,
      model: model,
    );
  }

  final String routeId;
  final LatLng originPoint;
  final LatLng destinationPoint;
  final String originName;
  final String destinationName;
  final TaxiRouteModel model;
}
