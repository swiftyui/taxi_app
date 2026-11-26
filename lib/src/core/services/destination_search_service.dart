import 'package:TaxiApp/src/core/models/destination_search_result.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:TaxiApp/src/core/services/osm_geocoding_service.dart';
import 'package:latlong2/latlong.dart';

class DestinationSearchException implements Exception {
  const DestinationSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DestinationSearchService {
  DestinationSearchService({OsmGeocodingService? geocoding})
    : _geocoding = geocoding ?? OsmGeocodingService();

  final OsmGeocodingService _geocoding;

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
      final locations = await _geocoding.search(normalizedQuery);
      final geocodedResults = <DestinationSearchResult>[];

      for (final location in locations) {
        geocodedResults.add(
          DestinationSearchResult(
            label: location.label,
            subtitle: location.subtitle,
            position: location.position,
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
}
