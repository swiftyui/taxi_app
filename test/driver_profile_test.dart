import 'package:TaxiApp/src/core/models/driver_profile.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
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

  test('DriverRoute parses an active scheduled route', () {
    final route = DriverRoute.fromJson('route-1', {
      'driverId': 'driver-1',
      'originName': 'Mamelodi',
      'destinationName': 'Pretoria CBD',
      'origin': const GeoPoint(-25.70, 28.32),
      'destination': const GeoPoint(-25.75, 28.19),
      'fare': 20,
      'serviceDays': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      'departureTime': '11:00',
      'notes': 'Main rank',
      'associationName': 'Hamba Taxi Association',
      'seatCapacity': 15,
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 9, 13)),
    });

    expect(route.id, 'route-1');
    expect(route.fare, 20);
    expect(route.serviceDays, hasLength(5));
    expect(route.departureTime, '11:00');
    expect(route.associationName, 'Hamba Taxi Association');

    final publicRoute = TaxiRouteModel.fromDriverRoute(route);
    expect(publicRoute.id, isNegative);
    expect(publicRoute.properties.route_id, 'driver:driver-1:route-1');
    expect(publicRoute.properties.assocname, 'Hamba Taxi Association');
    expect(publicRoute.properties.noofseats, 15);
    expect(publicRoute.properties.routelengt, greaterThan(0));
    expect(publicRoute.geometry.coordinates, hasLength(2));
  });
}
