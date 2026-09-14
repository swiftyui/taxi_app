import 'package:cloud_firestore/cloud_firestore.dart';

class RideRequest {
  const RideRequest({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.routeFeatureId,
    required this.routeId,
    required this.originName,
    required this.destinationName,
    required this.associationName,
    required this.fare,
    required this.pickupLocation,
    required this.status,
    required this.requestedAt,
    required this.expiredAt,
  });

  factory RideRequest.fromJson(String id, Map<String, dynamic> json) =>
      RideRequest(
        id: id,
        riderId: json['riderId'] as String,
        riderName: json['riderName'] as String,
        routeFeatureId: (json['routeFeatureId'] as num).toInt(),
        routeId: json['routeId'] as String,
        originName: json['originName'] as String,
        destinationName: json['destinationName'] as String,
        associationName: json['associationName'] as String,
        fare: (json['fare'] as num).toDouble(),
        pickupLocation: json['pickupLocation'] as GeoPoint,
        status: json['status'] as String,
        requestedAt: (json['requestedAt'] as Timestamp?)?.toDate(),
        expiredAt: (json['expiredAt'] as Timestamp?)?.toDate(),
      );

  static const notificationDuration = Duration(seconds: 15);

  final String id;
  final String riderId;
  final String riderName;
  final int routeFeatureId;
  final String routeId;
  final String originName;
  final String destinationName;
  final String associationName;
  final double fare;
  final GeoPoint pickupLocation;
  final String status;
  final DateTime? requestedAt;
  final DateTime? expiredAt;

  bool get isRequested => status == 'requested';
  bool get isExpired => status == 'expired';
  DateTime? get bannerExpiresAt => requestedAt?.add(notificationDuration);
}
