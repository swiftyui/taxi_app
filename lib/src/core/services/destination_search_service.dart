import 'dart:math' as math;

import 'package:TaxiApp/src/core/models/destination_search_result.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:TaxiApp/src/core/services/destination_query.dart';
import 'package:TaxiApp/src/core/services/destination_search_history.dart';
import 'package:TaxiApp/src/core/services/osm_geocoding_service.dart';
import 'package:TaxiApp/src/core/services/photon_place_search.dart';
import 'package:latlong2/latlong.dart';

class DestinationSearchException implements Exception {
  const DestinationSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DestinationSearchService {
  DestinationSearchService({
    OsmGeocodingService? geocoding,
    PhotonPlaceSearch? photon,
  }) : _geocoding = geocoding ?? OsmGeocodingService(),
       _photon = photon ?? PhotonPlaceSearch();

  final OsmGeocodingService _geocoding;
  final PhotonPlaceSearch _photon;
  final _lookups = <String, Future<List<DestinationSearchResult>>>{};
  final _liveLookups = <(String, LatLng?), List<DestinationSearchResult>>{};

  Future<List<DestinationSearchResult>> liveSuggestions(
    String query, {
    LatLng? near,
    Future<void>? abortTrigger,
  }) async {
    final trimmed = query.trim();
    if (DestinationQuery.normalize(trimmed).length < 3) {
      return const [];
    }
    // Photon only needs a city-scale bias. Rank using the precise fix locally.
    final area = near == null
        ? null
        : LatLng(
            (near.latitude * 10).round() / 10,
            (near.longitude * 10).round() / 10,
          );
    final key = (trimmed.toLowerCase(), area);
    final cached = _liveLookups.remove(key);
    if (cached != null) {
      _liveLookups[key] = cached;
      return cached;
    }
    final results = List<DestinationSearchResult>.unmodifiable(
      await _photon.search(trimmed, area: area, abortTrigger: abortTrigger),
    );
    _liveLookups[key] = results;
    if (_liveLookups.length > 32) {
      _liveLookups.remove(_liveLookups.keys.first);
    }
    return results;
  }

  List<DestinationSearchResult> suggestions({
    required String query,
    required Iterable<TaxiRouteModel> taxiRoutes,
    Iterable<DestinationSearchResult> savedPlaces = const [],
    Iterable<RecentDestinationSearch> recentSearches = const [],
    LatLng? near,
  }) {
    final matcher = DestinationQuery(query);
    if (matcher.normalized.length < 2) {
      return const [];
    }
    final matches =
        <
          ({
            DestinationSearchResult result,
            double score,
            int order,
            bool taxiStop,
          })
        >[];
    void add(
      DestinationSearchResult result, {
      String alias = '',
      bool taxiStop = false,
    }) {
      final labelMatch = matcher.score(result.label);
      final detailsMatch = matcher.score(
        '${result.label} ${result.subtitle} $alias',
      );
      final aliasMatch = alias.isEmpty ? null : matcher.score(alias);
      final scores = [
        ?labelMatch,
        if (aliasMatch != null) aliasMatch + (taxiStop ? 6 : 1),
        if (detailsMatch != null) detailsMatch + 4,
      ];
      if (scores.isNotEmpty) {
        scores.sort();
        matches.add((
          result: result,
          score: scores.first + _proximityPenalty(near, result.position),
          order: matches.length,
          taxiStop: taxiStop,
        ));
      }
    }

    for (final entry in recentSearches) {
      if (entry.destination case final place?) {
        add(place, alias: entry.query);
      }
    }
    for (final place in savedPlaces) {
      add(place);
    }
    for (final route in taxiRoutes) {
      final properties = route.properties;
      final label = properties.destname.trim();
      if (label.isEmpty || route.geometry.coordinates.isEmpty) {
        continue;
      }
      final coordinate = route.geometry.coordinates.last;
      add(
        DestinationSearchResult(
          label: label,
          subtitle: properties.destpnt.trim(),
          position: LatLng(coordinate[1], coordinate[0]),
        ),
        alias: '${properties.spd_label} ${properties.route_id}',
        taxiStop: true,
      );
    }
    matches.sort((left, right) {
      final comparison = left.score.compareTo(right.score);
      return comparison == 0 ? left.order.compareTo(right.order) : comparison;
    });
    final taxiAddresses = <(String, String)>{};
    final distinct = matches.where((match) {
      if (!match.taxiStop) {
        return true;
      }
      final name = DestinationQuery.normalize(match.result.label);
      final address = DestinationQuery.normalize(match.result.subtitle);
      return address.isEmpty ||
          address == name ||
          taxiAddresses.add((name, address));
    });
    return _deduplicate(distinct.map((match) => match.result)).take(8).toList();
  }

  Future<List<DestinationSearchResult>> search({
    required String query,
    Iterable<DestinationSearchResult> localResults = const [],
  }) async {
    final submitted = query.trim();
    final normalizedQuery = DestinationQuery.normalize(submitted);
    if (normalizedQuery.length < 3) {
      return const [];
    }

    try {
      final geocodedResults = await _searchOnline(submitted);
      return mergeSuggestions(
        query: submitted,
        local: localResults,
        online: geocodedResults,
      );
    } catch (_) {
      if (localResults.isNotEmpty) {
        return localResults.toList();
      }
      throw const DestinationSearchException(
        'Destination search is unavailable. Check your connection and retry.',
      );
    }
  }

  List<DestinationSearchResult> mergeSuggestions({
    required String query,
    required Iterable<DestinationSearchResult> local,
    required Iterable<DestinationSearchResult> online,
    LatLng? near,
  }) {
    final normalized = DestinationQuery.normalize(query);
    final matches = _deduplicate([
      ...local
          .where(
            (result) =>
                DestinationQuery.normalize(result.label).startsWith(normalized),
          )
          .take(3),
      ...online,
      ...local,
    ]).toList();
    if (near == null) {
      return matches;
    }
    final matcher = DestinationQuery(query);
    final ranked =
        [
          for (final (index, place) in matches.indexed)
            (
              place: place,
              order: index,
              score:
                  math.min(
                    matcher.score(place.label) ?? 28,
                    (matcher.score('${place.label} ${place.subtitle}') ?? 28) +
                        3,
                  ) +
                  _proximityPenalty(near, place.position),
            ),
        ]..sort((left, right) {
          final comparison = left.score.compareTo(right.score);
          return comparison == 0
              ? left.order.compareTo(right.order)
              : comparison;
        });
    return ranked.map((match) => match.place).toList();
  }

  static double _proximityPenalty(LatLng? near, LatLng destination) {
    if (near == null) {
      return 0;
    }
    const distance = Distance(calculator: Haversine(), roundResult: false);
    final meters = distance.as(LengthUnit.Meter, near, destination);
    // Prefer nearby matches without overwhelming a specific, distant query.
    return 18 * meters / (meters + 15000);
  }

  Future<List<DestinationSearchResult>> _searchOnline(String query) async {
    final key = query.toLowerCase();
    final cached = _lookups[key];
    if (cached != null) {
      return cached;
    }
    if (_lookups.length == 24) {
      _lookups.remove(_lookups.keys.first);
    }
    final lookup = _geocoding
        .search(query)
        .then(
          (locations) => [
            for (final location in locations)
              DestinationSearchResult(
                label: location.label,
                subtitle: location.subtitle,
                position: location.position,
              ),
          ],
        );
    _lookups[key] = lookup;
    try {
      return await lookup;
    } catch (_) {
      if (identical(_lookups[key], lookup)) {
        _lookups.remove(key);
      }
      rethrow;
    }
  }

  Iterable<DestinationSearchResult> _deduplicate(
    Iterable<DestinationSearchResult> results,
  ) sync* {
    const distance = Distance();
    final locations = <String, List<LatLng>>{};
    for (final result in results) {
      final label = DestinationQuery.normalize(result.label);
      final sameName = locations.putIfAbsent(label, () => []);
      if (!sameName.any(
        (point) => distance.as(LengthUnit.Meter, point, result.position) < 75,
      )) {
        sameName.add(result.position);
        yield result;
      }
    }
  }
}
