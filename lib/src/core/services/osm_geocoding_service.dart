import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsmPlace {
  const OsmPlace({
    required this.label,
    required this.subtitle,
    required this.position,
  });
  final String label;
  final String subtitle;
  final LatLng position;
}

/// No-key geocoding using OpenStreetMap's public Nominatim endpoint.
/// Requests are serialized to respect its public 1 request/second limit.
class OsmGeocodingService {
  OsmGeocodingService({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  static DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);
  static Future<void> _queue = Future.value();

  Future<List<OsmPlace>> search(
    String query, {
    String country = 'South Africa',
  }) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': '$query, $country',
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '5',
    });
    final response = await _get(uri);
    final data = jsonDecode(response.body);
    if (data is! List) {
      return const [];
    }
    return data.whereType<Map<String, dynamic>>().map(_parse).toList();
  }

  Future<String?> reverse(LatLng position) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': '${position.latitude}',
      'lon': '${position.longitude}',
      'format': 'jsonv2',
      'addressdetails': '1',
    });
    final response = await _get(uri);
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      return null;
    }
    final address = data['address'];
    if (address is Map<String, dynamic>) {
      final parts = [
        address['road'],
        address['suburb'],
        address['city'] ?? address['town'] ?? address['village'],
      ].whereType<String>().where((part) => part.trim().isNotEmpty).toSet();
      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
    }
    return data['name'] as String? ?? data['display_name'] as String?;
  }

  Future<http.Response> _get(Uri uri) async {
    final completer = Completer<void>();
    final previous = _queue;
    _queue = completer.future;
    await previous;
    try {
      final elapsed = DateTime.now().difference(_lastRequest);
      if (elapsed < const Duration(seconds: 1)) {
        await Future<void>.delayed(const Duration(seconds: 1) - elapsed);
      }
      _lastRequest = DateTime.now();
      final response = await _client
          .get(
            uri,
            headers: {
              'User-Agent': 'HambaGo/1.0 (com.hambago.taxiapp)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw HttpException('Nominatim returned HTTP ${response.statusCode}.');
      }
      return response;
    } finally {
      completer.complete();
    }
  }

  OsmPlace _parse(Map<String, dynamic> item) {
    final lat = double.parse(item['lat'] as String);
    final lon = double.parse(item['lon'] as String);
    final address = item['address'] as Map<String, dynamic>? ?? const {};
    final primary = [
      item['name'],
      address['road'],
      address['suburb'],
      address['city'] ?? address['town'] ?? address['village'],
    ].whereType<String>().where((part) => part.trim().isNotEmpty).toList();
    final label = primary.isEmpty
        ? (item['display_name'] as String? ?? 'Selected location')
        : primary.first;
    final subtitle = primary.skip(1).toSet().join(', ');
    return OsmPlace(
      label: label,
      subtitle: subtitle,
      position: LatLng(lat, lon),
    );
  }
}

class HttpException implements Exception {
  const HttpException(this.message);
  final String message;
  @override
  String toString() => message;
}
