import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    required this.isPrimary,
    required this.updatedAt,
  });

  factory EmergencyContact.fromJson(String id, Map<String, dynamic> json) {
    final updatedAt = json['updatedAt'];
    return EmergencyContact(
      id: id,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      relationship: json['relationship'] as String,
      isPrimary: json['isPrimary'] as bool,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
    );
  }

  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final bool isPrimary;
  final DateTime? updatedAt;
}
