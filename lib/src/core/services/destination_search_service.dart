import 'package:TaxiApp/src/core/models/destination_search_result.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DestinationSearchException implements Exception {
  const DestinationSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DestinationSearchService {
  DestinationSearchService({Geocoding? geocoding})
    : _geocoding = geocoding ?? Geocoding();

  final Geocoding _geocoding;

  Future<List<DestinationSearchResult>> search({
    required String query,
    required Iterable<TaxiRouteModel> taxiRoutes,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < 3) {
      return const [];
    }

    final localResults = _taxiRouteDestinations(normalizedQuery, taxiRoutes);

    try {
      final locations = await _geocoding.locationFromAddress(
        '$normalizedQuery, South Africa',
      );
      final geocodedResults = <DestinationSearchResult>[];

      for (final location in locations.take(5)) {
        final placemarks = await _geocoding.placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        final placemark = placemarks.isEmpty ? null : placemarks.first;
        final label = _placeLabel(placemark, normalizedQuery);
        final subtitle = _placeSubtitle(placemark);
        geocodedResults.add(
          DestinationSearchResult(
            label: label,
            subtitle: subtitle,
            position: LatLng(location.latitude, location.longitude),
          ),
        );
      }

      return _deduplicate([...localResults, ...geocodedResults]);
    } catch (error) {
      if (localResults.isNotEmpty) {
        return localResults;
      }
      throw const DestinationSearchException(
        'Destination search is unavailable. Check your connection and retry.',
      );
    }
  }

  List<DestinationSearchResult> _taxiRouteDestinations(
    String query,
    Iterable<TaxiRouteModel> routes,
  ) {
    final normalizedQuery = query.toLowerCase();
    final results = <DestinationSearchResult>[];

    for (final route in routes) {
      final properties = route.properties;
      final searchableText =
          '${properties.destname} ${properties.destpnt} '
                  '${properties.spd_label}'
              .toLowerCase();
      if (!searchableText.contains(normalizedQuery) ||
          route.geometry.coordinates.isEmpty) {
        continue;
      }

      final coordinate = route.geometry.coordinates.last;
      results.add(
        DestinationSearchResult(
          label: properties.destname.trim(),
          subtitle: properties.destpnt.trim(),
          position: LatLng(coordinate[1], coordinate[0]),
        ),
      );
    }

    return _deduplicate(results).take(5).toList();
  }

  List<DestinationSearchResult> _deduplicate(
    Iterable<DestinationSearchResult> results,
  ) {
    final seen = <String>{};
    return results.where((result) {
      final key =
          '${result.label.toLowerCase()}|'
          '${result.position.latitude.toStringAsFixed(5)}|'
          '${result.position.longitude.toStringAsFixed(5)}';
      return seen.add(key);
    }).toList();
  }

  String _placeLabel(Placemark? place, String fallback) {
    if (place == null) {
      return fallback;
    }
    return [place.name, place.street, place.locality]
        .whereType<String>()
        .map((value) => value.trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => fallback);
  }

  String _placeSubtitle(Placemark? place) => place == null
      ? ''
      : [
              place.street,
              place.subLocality,
              place.locality,
              place.administrativeArea,
            ]
            .whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .join(', ');
}
