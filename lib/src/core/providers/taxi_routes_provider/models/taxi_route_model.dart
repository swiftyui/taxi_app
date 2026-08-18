import 'package:json_annotation/json_annotation.dart';
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
  });
  factory TaxiRouteModel.fromJson(Map<String, dynamic> json) =>
      _$TaxiRouteModelFromJson(json);

  Map<String, dynamic> toJson() => _$TaxiRouteModelToJson(this);

  final TaxiRouteGeometry geometry;
  final int id;
  final String type;
  final TaxiRouteProperties properties;
}

class TaxiRouteGeometry {
  TaxiRouteGeometry({required this.type, required this.coordinates});

  factory TaxiRouteGeometry.fromJson(Map<String, dynamic> json) {
    final rawCoordinates = json['coordinates'];

    if (rawCoordinates is! List) {
      throw FormatException(
        'coordinates is not a List: ${rawCoordinates.runtimeType}',
      );
    }

    final coordinates = <List<double>>[];

    for (final coordinate in rawCoordinates) {
      if (coordinate is! List) {
        throw FormatException(
          'coordinate is not a List: '
          '${coordinate.runtimeType} - $coordinate',
        );
      }

      final point = <double>[];

      for (final value in coordinate) {
        if (value is! num) {
          /// be able to cater for [28.62946062250981, -25.459445018572698]
          if (value is String) {
            final parsedValue = double.tryParse(value);
            if (parsedValue != null) {
              point.add(parsedValue);
              continue;
            }
          }
          if (value is List) {
            for (final v in value) {
              if (v is num) {
                point.add(v.toDouble());
              } else {
                throw FormatException(
                  'Coordinate value is not a num: '
                  '${v.runtimeType} - $v',
                );
              }
            }
            continue;
          }
          throw FormatException(
            'Coordinate value is not a num: '
            '${value.runtimeType} - $value',
          );
        }

        point.add(value.toDouble());
      }

      coordinates.add(point);
    }

    return TaxiRouteGeometry(
      type: json['type'] as String,
      coordinates: coordinates,
    );
  }

  Map<String, dynamic> toJson() => {'type': type, 'coordinates': coordinates};

  final String type;
  final List<List<double>> coordinates;
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
