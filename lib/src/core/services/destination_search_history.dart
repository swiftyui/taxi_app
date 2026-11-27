import 'dart:convert';

import 'package:TaxiApp/src/core/models/destination_search_result.dart';
import 'package:TaxiApp/src/core/providers/shared_preferences/enums/shared_preference_key.dart';
import 'package:TaxiApp/src/core/providers/shared_preferences/shared_preference_manager.dart';
import 'package:TaxiApp/src/core/services/destination_query.dart';
import 'package:latlong2/latlong.dart';

class RecentDestinationSearch {
  const RecentDestinationSearch(this.query, {this.destination});

  final String query;
  final DestinationSearchResult? destination;

  String encode() => jsonEncode({
    'query': query,
    if (destination case final place?) ...{
      'label': place.label,
      'subtitle': place.subtitle,
      'latitude': place.position.latitude,
      'longitude': place.position.longitude,
    },
  });

  static RecentDestinationSearch? decode(String value) {
    if (!value.startsWith('{')) {
      // Older history values can contain just the query text.
      return value.trim().isEmpty ? null : RecentDestinationSearch(value);
    }
    final Object? data;
    try {
      data = jsonDecode(value);
    } on FormatException {
      return null;
    }
    if (data case {'query': final String query} when query.trim().isNotEmpty) {
      if (data
          case {
            'label': final String label,
            'subtitle': final String subtitle,
            'latitude': final num latitude,
            'longitude': final num longitude,
          }
          when label.trim().isNotEmpty &&
              latitude.abs() <= 90 &&
              longitude.abs() <= 180) {
        return RecentDestinationSearch(
          query,
          destination: DestinationSearchResult(
            label: label,
            subtitle: subtitle,
            position: LatLng(latitude.toDouble(), longitude.toDouble()),
          ),
        );
      }
      return RecentDestinationSearch(query);
    }
    return null;
  }
}

class DestinationSearchHistory {
  DestinationSearchHistory({ISharedPreferencesManager? preferences})
    : _preferences = preferences ?? SharedPreferencesManager();

  static const _limit = 12;
  static final _key = SharedPreferenceKey.recentSearches.value;
  final ISharedPreferencesManager _preferences;
  late final Future<List<RecentDestinationSearch>> _entries = _read();
  Future<void> _writeQueue = Future.value();

  Future<List<RecentDestinationSearch>> load() async =>
      List.unmodifiable(await _entries);

  Future<List<RecentDestinationSearch>> record(
    String query, {
    DestinationSearchResult? destination,
  }) async {
    final entries = await _entries;
    final normalized = DestinationQuery.normalize(query);
    if (normalized.isEmpty) {
      return List.unmodifiable(entries);
    }
    final existing = entries
        .where((entry) => DestinationQuery.normalize(entry.query) == normalized)
        .firstOrNull;
    final selected = destination ?? existing?.destination;
    entries.removeWhere((entry) {
      final place = entry.destination;
      return place == null
          ? DestinationQuery.normalize(entry.query) == normalized
          : place.searchIdentity == selected?.searchIdentity;
    });
    entries.insert(
      0,
      RecentDestinationSearch(query.trim(), destination: selected),
    );
    if (entries.length > _limit) {
      entries.removeRange(_limit, entries.length);
    }
    await _write(entries);
    return List.unmodifiable(entries);
  }

  Future<List<RecentDestinationSearch>> clear() async {
    final entries = await _entries;
    entries.clear();
    await _write(entries);
    return List.unmodifiable(entries);
  }

  Future<List<RecentDestinationSearch>> _read() async {
    try {
      final entries = await _preferences.getList(key: _key) ?? const [];
      return entries
          .map(RecentDestinationSearch.decode)
          .whereType<RecentDestinationSearch>()
          .take(_limit)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(List<RecentDestinationSearch> entries) {
    final encoded = entries.map((entry) => entry.encode()).toList();
    _writeQueue = _writeQueue.then((_) async {
      try {
        if (encoded.isEmpty) {
          await _preferences.removeValue(key: _key);
        } else {
          await _preferences.setValue(key: _key, value: encoded);
        }
      } catch (_) {
        // Search and its in-memory history still work without preferences.
      }
    });
    return _writeQueue;
  }
}
