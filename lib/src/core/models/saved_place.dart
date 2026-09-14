import 'package:TaxiApp/src/core/models/destination_search_result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum SavedPlaceType {
  home,
  work,
  custom;

  static SavedPlaceType fromValue(Object? value) => values.firstWhere(
    (type) => type.name == value,
    orElse: () => SavedPlaceType.custom,
  );
}

class SavedPlace {
  const SavedPlace({
    required this.id,
    required this.type,
    required this.label,
    required this.address,
    required this.position,
    required this.updatedAt,
  });

  factory SavedPlace.fromJson(String id, Map<String, dynamic> json) {
    final location = json['location'];
    if (location is! GeoPoint) {
      throw const FormatException('Saved place location is invalid.');
    }
    final updatedAt = json['updatedAt'];
    return SavedPlace(
      id: id,
      type: SavedPlaceType.fromValue(json['type']),
      label: json['label'] as String,
      address: json['address'] as String,
      position: LatLng(location.latitude, location.longitude),
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
    );
  }

  final String id;
  final SavedPlaceType type;
  final String label;
  final String address;
  final LatLng position;
  final DateTime? updatedAt;

  DestinationSearchResult get destination => DestinationSearchResult(
    label: label,
    subtitle: address,
    position: position,
  );
}
