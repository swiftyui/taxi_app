import 'package:google_maps_flutter/google_maps_flutter.dart';

class DestinationSearchResult {
  const DestinationSearchResult({
    required this.label,
    required this.subtitle,
    required this.position,
  });

  final String label;
  final String subtitle;
  final LatLng position;
}
