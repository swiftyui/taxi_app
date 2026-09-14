import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/nearby_taxi_route_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteRoute {
  const FavoriteRoute({
    required this.featureId,
    required this.routeId,
    required this.originName,
    required this.destinationName,
    required this.associationName,
    required this.fare,
    required this.addedAt,
  });

  factory FavoriteRoute.fromJson(Map<String, dynamic> json) {
    final addedAt = json['addedAt'];
    return FavoriteRoute(
      featureId: (json['featureId'] as num).toInt(),
      routeId: json['routeId'] as String,
      originName: json['originName'] as String,
      destinationName: json['destinationName'] as String,
      associationName: json['associationName'] as String,
      fare: (json['fare'] as num).toDouble(),
      addedAt: addedAt is Timestamp ? addedAt.toDate() : null,
    );
  }

  factory FavoriteRoute.fromRoute(NearbyTaxiRouteModel route) => FavoriteRoute(
    featureId: route.model.id,
    routeId: route.routeId,
    originName: route.originName,
    destinationName: route.destinationName,
    associationName: route.model.properties.assocname,
    fare: route.model.properties.fare,
    addedAt: null,
  );

  final int featureId;
  final String routeId;
  final String originName;
  final String destinationName;
  final String associationName;
  final double fare;
  final DateTime? addedAt;

  String get documentId => featureId.toString();

  Map<String, Object?> toJson() => {
    'featureId': featureId,
    'routeId': routeId,
    'originName': originName,
    'destinationName': destinationName,
    'associationName': associationName,
    'fare': fare,
    'addedAt': FieldValue.serverTimestamp(),
  };
}
