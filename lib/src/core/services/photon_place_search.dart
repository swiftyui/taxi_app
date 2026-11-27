import 'dart:async';
import 'dart:convert';

import 'package:TaxiApp/src/core/models/destination_search_result.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PhotonPlaceSearch {
  PhotonPlaceSearch({http.Client? client, Uri? endpoint})
    : _client = client ?? http.Client(),
      _endpoint = endpoint ?? Uri.parse(_defaultEndpoint);

  static const _defaultEndpoint = String.fromEnvironment(
    'HAMBA_PHOTON_URL',
    defaultValue: 'https://photon.komoot.io/api/',
  );

  final http.Client _client;
  final Uri _endpoint;

  Future<List<DestinationSearchResult>> search(
    String query, {
    Future<void>? abortTrigger,
  }) async {
    final uri = _endpoint.replace(
      queryParameters: {
        ..._endpoint.queryParameters,
        'q': query,
        'countrycode': 'ZA',
        'limit': '6',
      },
    );
    final finished = Completer<void>();
    final request =
        http.AbortableRequest(
            'GET',
            uri,
            abortTrigger: abortTrigger == null
                ? finished.future
                : Future.any([abortTrigger, finished.future]),
          )
          ..headers.addAll({
            'Accept': 'application/json',
            'User-Agent': 'HambaGo/1.0 (com.vanzylarno.taxiApp)',
          });

    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) {
        throw http.ClientException(
          'Photon returned HTTP ${response.statusCode}.',
        );
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data case {'features': final List<Object?> features}) {
        return features
            .map(_parsePlace)
            .whereType<DestinationSearchResult>()
            .toList();
      }
      throw const FormatException('Invalid Photon response.');
    } finally {
      finished.complete();
    }
  }

  DestinationSearchResult? _parsePlace(Object? feature) {
    if (feature case {
      'properties': final Map<String, dynamic> properties,
      'geometry': {
        'type': 'Point',
        'coordinates': [final num longitude, final num latitude, ...],
      },
    } when longitude.abs() <= 180 && latitude.abs() <= 90) {
      String field(String key) => switch (properties[key]) {
        final String value => value.trim(),
        final num value when key == 'housenumber' => value.toString(),
        _ => '',
      };

      final country = field('countrycode').toUpperCase();
      if (country.isNotEmpty && country != 'ZA') {
        return null;
      }
      final street = [
        field('housenumber'),
        field('street'),
      ].where((part) => part.isNotEmpty).join(' ');
      final parts = [
        field('name'),
        street,
        field('locality'),
        field('district'),
        field('city'),
        field('state'),
      ].where((part) => part.isNotEmpty).toSet().toList();
      if (parts.isNotEmpty) {
        return DestinationSearchResult(
          label: parts.first,
          subtitle: parts.skip(1).join(', '),
          position: LatLng(latitude.toDouble(), longitude.toDouble()),
        );
      }
    }
    return null;
  }
}
