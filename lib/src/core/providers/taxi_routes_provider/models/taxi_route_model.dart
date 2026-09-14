import 'package:json_annotation/json_annotation.dart';
import 'dart:math' as math;

import 'package:TaxiApp/src/core/models/driver_profile.dart';
part 'taxi_route_model.g.dart';

@JsonSerializable()
class TaxiRouteParent {
  TaxiRouteParent({required this.features});
  factory TaxiRouteParent.fromJson(Map<String, dynamic> json) =>
      _$TaxiRouteParentFromJson(json);
  Map<String, dynamic> toJson() => _$TaxiRouteParentToJson(this);

  final List<TaxiRouteModel> features;
}

@JsonSerializable()
class TaxiRouteModel {
  TaxiRouteModel({
    required this.geometry,
    required this.id,
    required this.type,
    required this.properties,
    this.serviceDays = const [],
    this.departureTime,
  });
  factory TaxiRouteModel.fromJson(Map<String, dynamic> json) =>
      _$TaxiRouteModelFromJson(json);

  factory TaxiRouteModel.fromDriverRoute(DriverRoute route) {
    final featureId = _stableDriverFeatureId(route.driverId, route.id);
    final coordinates = [
      [route.origin.longitude, route.origin.latitude],
      [route.destination.longitude, route.destination.latitude],
    ];
    final routeLength = _distanceInKilometres(
      route.origin.latitude,
      route.origin.longitude,
      route.destination.latitude,
      route.destination.longitude,
    );
    return TaxiRouteModel(
      geometry: TaxiRouteGeometry(type: 'LineString', parts: [coordinates]),
      id: featureId,
      type: 'Feature',
      serviceDays: route.serviceDays,
      departureTime: route.departureTime,
      properties: TaxiRouteProperties(
        fid: featureId,
        noofvehs: 1,
        fare: route.fare,
        route_id: 'driver:${route.driverId}:${route.id}',
        shpname: '',
        spd_mn_nm: '',
        destpnt: route.destinationName,
        trnsferpnt: '',
        alt_fare3: 0,
        alt_fare2: 0,
        alt_fare1: 0,
        originname: route.originName,
        routelengt: routeLength,
        noassoc: 1,
        alt_fare4: 0,
        regionname: '',
        destmuni: '',
        spd_dc_nm: '',
        spd_sp_nm: '',
        origintype: 'Driver route',
        period: 0,
        assocroute: '',
        region_id: 0,
        spo_sp_nm: '',
        spo_featur: 0,
        spd_label: route.destinationName,
        assocname: route.associationName,
        destname: route.destinationName,
        originmuni: '',
        spo_mn_nm: '',
        SHAPE__Length: routeLength * 1000,
        matchid: featureId,
        spd_mp_nm: '',
        assoc_id: 0,
        noofseats: route.seatCapacity,
        trackid: featureId,
        shapeno: '',
        shape_leng: routeLength * 1000,
        originpnt: '${route.originName} · ${route.departureTime}',
        vianame: route.notes,
        shapefile: 'HambaGo driver route',
        surveydate: route.createdAt?.year ?? DateTime.now().year,
        spo_dc_nm: '',
        spo_mp_nm: '',
        spo_label: route.originName,
        routeleg: 1,
        spd_featur: 0,
        dayofweek: route.serviceDays.first,
        category: 'Driver route',
        desttype: 'Driver route',
      ),
    );
  }

  Map<String, dynamic> toJson() => _$TaxiRouteModelToJson(this);

  final TaxiRouteGeometry geometry;
  final int id;
  final String type;
  final TaxiRouteProperties properties;
  final List<String> serviceDays;
  final String? departureTime;

  static int _stableDriverFeatureId(String driverId, String routeId) {
    var hash = 0x811c9dc5;
    for (final codeUnit in '$driverId/$routeId'.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return -(hash == 0 ? 1 : hash);
  }

  static double _distanceInKilometres(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const earthRadiusKilometres = 6371.0;
    final latitudeDelta = _toRadians(endLatitude - startLatitude);
    final longitudeDelta = _toRadians(endLongitude - startLongitude);
    final startLatitudeRadians = _toRadians(startLatitude);
    final endLatitudeRadians = _toRadians(endLatitude);
    final haversine =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(startLatitudeRadians) *
            math.cos(endLatitudeRadians) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    return earthRadiusKilometres *
        2 *
        math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}

class TaxiRouteGeometry {
  TaxiRouteGeometry({required this.type, required this.parts});

  factory TaxiRouteGeometry.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    final rawCoordinates = json['coordinates'];

    if (type is! String) {
      throw FormatException('geometry type is not a String: $type');
    }
    if (rawCoordinates is! List) {
      throw FormatException(
        'coordinates is not a List: ${rawCoordinates.runtimeType}',
      );
    }

    final parts = switch (type) {
      'LineString' => [_parseLineString(rawCoordinates)],
      'MultiLineString' =>
        rawCoordinates.map((part) => _parseLineString(part)).toList(),
      _ => throw FormatException('Unsupported taxi route geometry: $type'),
    };

    return TaxiRouteGeometry(type: type, parts: parts);
  }

  static List<List<double>> _parseLineString(Object? rawCoordinates) {
    if (rawCoordinates is! List) {
      throw FormatException(
        'line coordinates are not a List: ${rawCoordinates.runtimeType}',
      );
    }

    return rawCoordinates.map<List<double>>((coordinate) {
      if (coordinate is! List || coordinate.length < 2) {
        throw FormatException('Invalid GeoJSON position: $coordinate');
      }

      final longitude = _parseCoordinate(coordinate[0]);
      final latitude = _parseCoordinate(coordinate[1]);
      return [longitude, latitude];
    }).toList();
  }

  static double _parseCoordinate(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final parsedValue = double.tryParse(value);
      if (parsedValue != null) {
        return parsedValue;
      }
    }
    throw FormatException(
      'Coordinate value is not numeric: ${value.runtimeType} - $value',
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'coordinates': type == 'LineString' ? parts.single : parts,
  };

  final String type;
  final List<List<List<double>>> parts;

  List<List<double>> get coordinates => [for (final part in parts) ...part];
}

@JsonSerializable()
class TaxiRouteProperties {
  TaxiRouteProperties({
    required this.fid,
    required this.noofvehs,
    required this.fare,
    required this.route_id,
    required this.shpname,
    required this.spd_mn_nm,
    required this.destpnt,
    required this.trnsferpnt,
    required this.alt_fare3,
    required this.alt_fare2,
    required this.alt_fare1,
    required this.originname,
    required this.routelengt,
    required this.noassoc,
    required this.alt_fare4,
    required this.regionname,
    required this.destmuni,
    required this.spd_dc_nm,
    required this.spd_sp_nm,
    required this.origintype,
    required this.period,
    required this.assocroute,
    required this.region_id,
    required this.spo_sp_nm,
    required this.spo_featur,
    required this.spd_label,
    required this.assocname,
    required this.destname,
    required this.originmuni,
    required this.spo_mn_nm,
    required this.SHAPE__Length,
    required this.matchid,
    required this.spd_mp_nm,
    required this.assoc_id,
    required this.noofseats,
    required this.trackid,
    required this.shapeno,
    required this.shape_leng,
    required this.originpnt,
    required this.vianame,
    required this.shapefile,
    required this.surveydate,
    required this.spo_dc_nm,
    required this.spo_mp_nm,
    required this.spo_label,
    required this.routeleg,
    required this.spd_featur,
    required this.dayofweek,
    required this.category,
    required this.desttype,
  });

  factory TaxiRouteProperties.fromJson(Map<String, dynamic> json) =>
      _$TaxiRoutePropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$TaxiRoutePropertiesToJson(this);

  final int fid;
  final int noofvehs;
  final double fare;
  final String route_id;
  final String shpname;
  final String spd_mn_nm;
  final String destpnt;
  final String trnsferpnt;
  final double alt_fare3;
  final double alt_fare2;
  final double alt_fare1;
  final String originname;
  final double routelengt;
  final int noassoc;
  final double alt_fare4;
  final String regionname;
  final String destmuni;
  final String spd_dc_nm;
  final String spd_sp_nm;
  final String origintype;
  final int period;
  final String assocroute;
  final int region_id;
  final String spo_sp_nm;
  final int spo_featur;
  final String spd_label;
  final String assocname;
  final String destname;
  final String originmuni;
  final String spo_mn_nm;
  final double SHAPE__Length;
  final int matchid;
  final String spd_mp_nm;
  final int assoc_id;
  final int noofseats;
  final int trackid;
  final String shapeno;
  final double shape_leng;
  final String originpnt;
  final String vianame;
  final String shapefile;
  final int surveydate;
  final String spo_dc_nm;
  final String spo_mp_nm;
  final String spo_label;
  final int routeleg;
  final int spd_featur;
  final String dayofweek;
  final String category;
  final String desttype;
}
