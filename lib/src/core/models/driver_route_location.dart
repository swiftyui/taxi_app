import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverRouteLocation {
  const DriverRouteLocation({required this.label, required this.position});

  final String label;
  final LatLng position;
}
