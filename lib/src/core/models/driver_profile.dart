import 'package:cloud_firestore/cloud_firestore.dart';

class DriverProfile {
  const DriverProfile({
    required this.contactNumber,
    required this.driverLicenceNumber,
    required this.operatingPermitNumber,
    required this.associationName,
    required this.vehicleRegistration,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.seatCapacity,
    required this.updatedAt,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) => DriverProfile(
    contactNumber: json['contactNumber'] as String,
    driverLicenceNumber: json['driverLicenceNumber'] as String,
    operatingPermitNumber: json['operatingPermitNumber'] as String,
    associationName: json['associationName'] as String,
    vehicleRegistration: json['vehicleRegistration'] as String,
    vehicleMake: json['vehicleMake'] as String,
    vehicleModel: json['vehicleModel'] as String,
    vehicleColor: json['vehicleColor'] as String,
    seatCapacity: (json['seatCapacity'] as num).toInt(),
    updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
  );

  final String contactNumber;
  final String driverLicenceNumber;
  final String operatingPermitNumber;
  final String associationName;
  final String vehicleRegistration;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleColor;
  final int seatCapacity;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
    'contactNumber': contactNumber,
    'driverLicenceNumber': driverLicenceNumber,
    'operatingPermitNumber': operatingPermitNumber,
    'associationName': associationName,
    'vehicleRegistration': vehicleRegistration,
    'vehicleMake': vehicleMake,
    'vehicleModel': vehicleModel,
    'vehicleColor': vehicleColor,
    'seatCapacity': seatCapacity,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class DriverRoute {
  const DriverRoute({
    required this.id,
    required this.driverId,
    required this.originName,
    required this.destinationName,
    required this.origin,
    required this.destination,
    required this.fare,
    required this.serviceDays,
    required this.departureTime,
    required this.notes,
    required this.associationName,
    required this.seatCapacity,
    required this.createdAt,
  });

  factory DriverRoute.fromJson(String id, Map<String, dynamic> json) =>
      DriverRoute(
        id: id,
        driverId: json['driverId'] as String,
        originName: json['originName'] as String,
        destinationName: json['destinationName'] as String,
        origin: json['origin'] as GeoPoint,
        destination: json['destination'] as GeoPoint,
        fare: (json['fare'] as num).toDouble(),
        serviceDays: List<String>.from(json['serviceDays'] as List),
        departureTime: json['departureTime'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        associationName:
            json['associationName'] as String? ?? 'Independent HambaGo driver',
        seatCapacity: (json['seatCapacity'] as num?)?.toInt() ?? 1,
        createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      );

  final String id;
  final String driverId;
  final String originName;
  final String destinationName;
  final GeoPoint origin;
  final GeoPoint destination;
  final double fare;
  final List<String> serviceDays;
  final String departureTime;
  final String notes;
  final String associationName;
  final int seatCapacity;
  final DateTime? createdAt;
}
