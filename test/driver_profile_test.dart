import 'package:TaxiApp/src/core/models/driver_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DriverProfile parses persisted taxi details', () {
    final updatedAt = Timestamp.fromDate(DateTime.utc(2026, 9, 13));
    final profile = DriverProfile.fromJson({
      'contactNumber': '0821234567',
      'driverLicenceNumber': 'DL12345',
      'operatingPermitNumber': 'OP12345',
      'associationName': 'Hamba Taxi Association',
      'vehicleRegistration': 'ABC 123 GP',
      'vehicleMake': 'Toyota',
      'vehicleModel': 'Quantum',
      'vehicleColor': 'White',
      'seatCapacity': 15,
      'updatedAt': updatedAt,
    });

    expect(profile.vehicleRegistration, 'ABC 123 GP');
    expect(profile.seatCapacity, 15);
    expect(profile.updatedAt, updatedAt.toDate());
  });

  test('DriverRoute parses a pending route submission', () {
    final route = DriverRoute.fromJson('route-1', {
      'originName': 'Mamelodi',
      'destinationName': 'Pretoria CBD',
      'fare': 20,
      'serviceDays': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      'notes': 'Main rank',
      'status': 'pendingReview',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 9, 13)),
    });

    expect(route.id, 'route-1');
    expect(route.fare, 20);
    expect(route.serviceDays, hasLength(5));
    expect(route.status, 'pendingReview');
  });
}
