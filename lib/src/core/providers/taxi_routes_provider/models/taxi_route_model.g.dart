// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taxi_route_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaxiRouteParent _$TaxiRouteParentFromJson(Map<String, dynamic> json) =>
    TaxiRouteParent(
      features: (json['features'] as List<dynamic>)
          .map((e) => TaxiRouteModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TaxiRouteParentToJson(TaxiRouteParent instance) =>
    <String, dynamic>{'features': instance.features};

TaxiRouteModel _$TaxiRouteModelFromJson(Map<String, dynamic> json) =>
    TaxiRouteModel(
      geometry: TaxiRouteGeometry.fromJson(
        json['geometry'] as Map<String, dynamic>,
      ),
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      properties: TaxiRouteProperties.fromJson(
        json['properties'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$TaxiRouteModelToJson(TaxiRouteModel instance) =>
    <String, dynamic>{
      'geometry': instance.geometry,
      'id': instance.id,
      'type': instance.type,
      'properties': instance.properties,
    };

TaxiRouteProperties _$TaxiRoutePropertiesFromJson(Map<String, dynamic> json) =>
    TaxiRouteProperties(
      fid: (json['fid'] as num).toInt(),
      noofvehs: (json['noofvehs'] as num).toInt(),
      fare: (json['fare'] as num).toDouble(),
      route_id: json['route_id'] as String,
      shpname: json['shpname'] as String,
      spd_mn_nm: json['spd_mn_nm'] as String,
      destpnt: json['destpnt'] as String,
      trnsferpnt: json['trnsferpnt'] as String,
      alt_fare3: (json['alt_fare3'] as num).toDouble(),
      alt_fare2: (json['alt_fare2'] as num).toDouble(),
      alt_fare1: (json['alt_fare1'] as num).toDouble(),
      originname: json['originname'] as String,
      routelengt: (json['routelengt'] as num).toDouble(),
      noassoc: (json['noassoc'] as num).toInt(),
      alt_fare4: (json['alt_fare4'] as num).toDouble(),
      regionname: json['regionname'] as String,
      destmuni: json['destmuni'] as String,
      spd_dc_nm: json['spd_dc_nm'] as String,
      spd_sp_nm: json['spd_sp_nm'] as String,
      origintype: json['origintype'] as String,
      period: (json['period'] as num).toInt(),
      assocroute: json['assocroute'] as String,
      region_id: (json['region_id'] as num).toInt(),
      spo_sp_nm: json['spo_sp_nm'] as String,
      spo_featur: (json['spo_featur'] as num).toInt(),
      spd_label: json['spd_label'] as String,
      assocname: json['assocname'] as String,
      destname: json['destname'] as String,
      originmuni: json['originmuni'] as String,
      spo_mn_nm: json['spo_mn_nm'] as String,
      SHAPE__Length: (json['SHAPE__Length'] as num).toDouble(),
      matchid: (json['matchid'] as num).toInt(),
      spd_mp_nm: json['spd_mp_nm'] as String,
      assoc_id: (json['assoc_id'] as num).toInt(),
      noofseats: (json['noofseats'] as num).toInt(),
      trackid: (json['trackid'] as num).toInt(),
      shapeno: json['shapeno'] as String,
      shape_leng: (json['shape_leng'] as num).toDouble(),
      originpnt: json['originpnt'] as String,
      vianame: json['vianame'] as String,
      shapefile: json['shapefile'] as String,
      surveydate: (json['surveydate'] as num).toInt(),
      spo_dc_nm: json['spo_dc_nm'] as String,
      spo_mp_nm: json['spo_mp_nm'] as String,
      spo_label: json['spo_label'] as String,
      routeleg: (json['routeleg'] as num).toInt(),
      spd_featur: (json['spd_featur'] as num).toInt(),
      dayofweek: json['dayofweek'] as String,
      category: json['category'] as String,
      desttype: json['desttype'] as String,
    );

Map<String, dynamic> _$TaxiRoutePropertiesToJson(
  TaxiRouteProperties instance,
) => <String, dynamic>{
  'fid': instance.fid,
  'noofvehs': instance.noofvehs,
  'fare': instance.fare,
  'route_id': instance.route_id,
  'shpname': instance.shpname,
  'spd_mn_nm': instance.spd_mn_nm,
  'destpnt': instance.destpnt,
  'trnsferpnt': instance.trnsferpnt,
  'alt_fare3': instance.alt_fare3,
  'alt_fare2': instance.alt_fare2,
  'alt_fare1': instance.alt_fare1,
  'originname': instance.originname,
  'routelengt': instance.routelengt,
  'noassoc': instance.noassoc,
  'alt_fare4': instance.alt_fare4,
  'regionname': instance.regionname,
  'destmuni': instance.destmuni,
  'spd_dc_nm': instance.spd_dc_nm,
  'spd_sp_nm': instance.spd_sp_nm,
  'origintype': instance.origintype,
  'period': instance.period,
  'assocroute': instance.assocroute,
  'region_id': instance.region_id,
  'spo_sp_nm': instance.spo_sp_nm,
  'spo_featur': instance.spo_featur,
  'spd_label': instance.spd_label,
  'assocname': instance.assocname,
  'destname': instance.destname,
  'originmuni': instance.originmuni,
  'spo_mn_nm': instance.spo_mn_nm,
  'SHAPE__Length': instance.SHAPE__Length,
  'matchid': instance.matchid,
  'spd_mp_nm': instance.spd_mp_nm,
  'assoc_id': instance.assoc_id,
  'noofseats': instance.noofseats,
  'trackid': instance.trackid,
  'shapeno': instance.shapeno,
  'shape_leng': instance.shape_leng,
  'originpnt': instance.originpnt,
  'vianame': instance.vianame,
  'shapefile': instance.shapefile,
  'surveydate': instance.surveydate,
  'spo_dc_nm': instance.spo_dc_nm,
  'spo_mp_nm': instance.spo_mp_nm,
  'spo_label': instance.spo_label,
  'routeleg': instance.routeleg,
  'spd_featur': instance.spd_featur,
  'dayofweek': instance.dayofweek,
  'category': instance.category,
  'desttype': instance.desttype,
};
