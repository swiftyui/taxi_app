import 'package:latlong2/latlong.dart';

class DestinationSearchResult {
  const DestinationSearchResult({
    required this.label,
    required this.subtitle,
    required this.position,
  });

  final String label;
  final String subtitle;
  final LatLng position;

  String get searchIdentity =>
      '${label.trim().toLowerCase()}|'
      '${position.latitude.toStringAsFixed(5)}|'
      '${position.longitude.toStringAsFixed(5)}';
}
