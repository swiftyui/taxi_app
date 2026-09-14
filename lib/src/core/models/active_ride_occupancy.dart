import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveRideOccupancy {
  const ActiveRideOccupancy({
    required this.userId,
    required this.routeFeatureId,
    required this.routeId,
    required this.enteredAt,
    required this.expiresAt,
  });

  factory ActiveRideOccupancy.fromJson(Map<String, dynamic> json) =>
      ActiveRideOccupancy(
        userId: json['userId'] as String,
        routeFeatureId: (json['routeFeatureId'] as num).toInt(),
        routeId: json['routeId'] as String,
        enteredAt: (json['enteredAt'] as Timestamp?)?.toDate(),
        expiresAt: (json['expiresAt'] as Timestamp).toDate(),
      );

  final String userId;
  final int routeFeatureId;
  final String routeId;
  final DateTime? enteredAt;
  final DateTime expiresAt;

  bool isActiveAt(DateTime time) => expiresAt.isAfter(time);
}
