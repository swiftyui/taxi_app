import 'package:TaxiApp/src/core/models/taxi_journey.dart';

enum TravelLogStatus { inProgress, completed }

class TravelLogRoute {
  const TravelLogRoute({
    required this.featureId,
    required this.routeId,
    required this.originName,
    required this.destinationName,
    required this.associationName,
    required this.fare,
  });

  factory TravelLogRoute.fromJson(Map<String, dynamic> json) => TravelLogRoute(
    featureId: json['featureId'] as int,
    routeId: json['routeId'] as String,
    originName: json['originName'] as String,
    destinationName: json['destinationName'] as String,
    associationName: json['associationName'] as String,
    fare: (json['fare'] as num).toDouble(),
  );

  final int featureId;
  final String routeId;
  final String originName;
  final String destinationName;
  final String associationName;
  final double fare;

  Map<String, dynamic> toJson() => {
    'featureId': featureId,
    'routeId': routeId,
    'originName': originName,
    'destinationName': destinationName,
    'associationName': associationName,
    'fare': fare,
  };
}

class TravelLogEntry {
  const TravelLogEntry({
    required this.id,
    required this.startedAt,
    required this.originName,
    required this.destinationName,
    required this.routes,
    required this.status,
    this.completedAt,
  });

  factory TravelLogEntry.fromJourney({
    required String id,
    required TaxiJourney journey,
    required DateTime startedAt,
  }) => TravelLogEntry(
    id: id,
    startedAt: startedAt,
    originName: journey.taxiLegs.first.route.properties.originname,
    destinationName: journey.destination.label,
    routes: journey.taxiLegs
        .map(
          (leg) => TravelLogRoute(
            featureId: leg.route.properties.fid,
            routeId: leg.route.properties.route_id,
            originName: leg.route.properties.originname,
            destinationName: leg.route.properties.destname,
            associationName: leg.route.properties.assocname,
            fare: leg.route.properties.fare,
          ),
        )
        .toList(growable: false),
    status: TravelLogStatus.inProgress,
  );

  factory TravelLogEntry.fromJson(Map<String, dynamic> json) => TravelLogEntry(
    id: json['id'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    completedAt: json['completedAt'] == null
        ? null
        : DateTime.parse(json['completedAt'] as String),
    originName: json['originName'] as String,
    destinationName: json['destinationName'] as String,
    routes: (json['routes'] as List<dynamic>)
        .map(
          (route) =>
              TravelLogRoute.fromJson(Map<String, dynamic>.from(route as Map)),
        )
        .toList(growable: false),
    status: TravelLogStatus.values.byName(json['status'] as String),
  );

  final String id;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String originName;
  final String destinationName;
  final List<TravelLogRoute> routes;
  final TravelLogStatus status;

  TravelLogEntry completed(DateTime completedAt) => TravelLogEntry(
    id: id,
    startedAt: startedAt,
    completedAt: completedAt,
    originName: originName,
    destinationName: destinationName,
    routes: routes,
    status: TravelLogStatus.completed,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'completedAt': completedAt?.toUtc().toIso8601String(),
    'originName': originName,
    'destinationName': destinationName,
    'routes': routes.map((route) => route.toJson()).toList(growable: false),
    'status': status.name,
  };
}
