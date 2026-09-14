import 'dart:async';
import 'dart:convert';

import 'package:TaxiApp/src/core/env/env.dart';
import 'package:TaxiApp/src/core/models/taxi_journey.dart';
import 'package:TaxiApp/src/core/services/taxi_routing_service.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';

class WalkingDirectionsException implements Exception {
  const WalkingDirectionsException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoogleWalkingDirectionsService {
  GoogleWalkingDirectionsService({Client? client, String? apiKey})
    : _client = client ?? Client(),
      _apiKey = apiKey ?? Env.googleMapsApiKey;

  static final Uri _routesEndpoint = Uri.parse(
    'https://routes.googleapis.com/directions/v2:computeRoutes',
  );
  static const _fieldMask =
      'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline';

  final Client _client;
  final String _apiKey;

  Future<TaxiJourney> enrichJourney(TaxiJourney journey) async {
    final updatedSteps = await Future.wait(journey.steps.map(_enrichStep));
    return journey.withSteps(updatedSteps);
  }

  Future<JourneyStep> _enrichStep(JourneyStep step) async {
    if (step.type != JourneyStepType.walk &&
        step.type != JourneyStepType.transfer) {
      return step;
    }
    try {
      final route = await walkingRoute(
        origin: step.path.first,
        destination: step.path.last,
      );
      final isTransfer = step.type == JourneyStepType.transfer;
      return step.withWalkingRoute(
        path: route.path,
        distanceMeters: route.distanceMeters,
        duration: route.duration,
        instruction: isTransfer
            ? step.instruction
            : 'Walk ${TaxiRoutingService.formatDistance(route.distanceMeters)}',
        detail: isTransfer
            ? '${_durationLabel(route.duration)} via the Google Maps '
                  'walking route. Confirm the transfer point with the driver.'
            : '${_durationLabel(route.duration)} via the Google Maps '
                  'walking route. ${step.detail}',
      );
    } on WalkingDirectionsException catch (error, stackTrace) {
      debugPrint('Unable to map walking connector: $error\n$stackTrace');
      return step;
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('Google walking route timed out: $error\n$stackTrace');
      return step;
    } on ClientException catch (error, stackTrace) {
      debugPrint('Google walking route failed: $error\n$stackTrace');
      return step;
    } on FormatException catch (error, stackTrace) {
      debugPrint(
        'Google walking route response was invalid: $error\n$stackTrace',
      );
      return step;
    }
  }

  Future<GoogleWalkingRoute> walkingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw const WalkingDirectionsException(
        'Google Maps API key is not configured.',
      );
    }
    final response = await _client
        .post(
          _routesEndpoint,
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _apiKey,
            'X-Goog-FieldMask': _fieldMask,
          },
          body: jsonEncode({
            'origin': {
              'location': {
                'latLng': {
                  'latitude': origin.latitude,
                  'longitude': origin.longitude,
                },
              },
            },
            'destination': {
              'location': {
                'latLng': {
                  'latitude': destination.latitude,
                  'longitude': destination.longitude,
                },
              },
            },
            'travelMode': 'WALK',
            'computeAlternativeRoutes': false,
            'languageCode': 'en',
            'units': 'METRIC',
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WalkingDirectionsException(
        'Google Routes returned HTTP ${response.statusCode}.',
      );
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const WalkingDirectionsException(
        'Google Routes returned an invalid response.',
      );
    }
    final routes = body['routes'];
    if (routes is! List || routes.isEmpty) {
      throw const WalkingDirectionsException('No pedestrian route was found.');
    }
    final route = routes.first;
    if (route is! Map<String, dynamic>) {
      throw const WalkingDirectionsException(
        'Google Routes returned an invalid route.',
      );
    }
    final encodedPolyline =
        (route['polyline'] as Map<String, dynamic>?)?['encodedPolyline'];
    final distanceMeters = route['distanceMeters'];
    final duration = route['duration'];
    if (encodedPolyline is! String ||
        encodedPolyline.isEmpty ||
        distanceMeters is! num ||
        duration is! String) {
      throw const WalkingDirectionsException(
        'Google Routes omitted required walking directions.',
      );
    }
    final path = decodePolyline(encodedPolyline);
    if (path.length < 2) {
      throw const WalkingDirectionsException(
        'Google Routes returned an empty walking path.',
      );
    }
    return GoogleWalkingRoute(
      path: path,
      distanceMeters: distanceMeters.toDouble(),
      duration: _parseDuration(duration),
    );
  }

  @visibleForTesting
  static List<LatLng> decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var latitude = 0;
    var longitude = 0;
    while (index < encoded.length) {
      final latitudeResult = _decodeValue(encoded, index);
      index = latitudeResult.nextIndex;
      latitude += latitudeResult.value;
      final longitudeResult = _decodeValue(encoded, index);
      index = longitudeResult.nextIndex;
      longitude += longitudeResult.value;
      points.add(LatLng(latitude / 1e5, longitude / 1e5));
    }
    return points;
  }

  static _DecodedValue _decodeValue(String encoded, int startIndex) {
    var index = startIndex;
    var result = 0;
    var shift = 0;
    int byte;
    do {
      if (index >= encoded.length) {
        throw const WalkingDirectionsException('Invalid encoded polyline.');
      }
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    final value = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
    return _DecodedValue(value: value, nextIndex: index);
  }

  static Duration _parseDuration(String value) {
    final match = RegExp(r'^([0-9]+(?:\.[0-9]+)?)s$').firstMatch(value);
    if (match == null) {
      throw const WalkingDirectionsException(
        'Google Routes returned an invalid duration.',
      );
    }
    final seconds = double.parse(match.group(1)!);
    return Duration(milliseconds: (seconds * 1000).round());
  }

  static String _durationLabel(Duration duration) {
    final minutes = (duration.inSeconds / 60).ceil().clamp(1, 999);
    return '$minutes min';
  }
}

class GoogleWalkingRoute {
  const GoogleWalkingRoute({
    required this.path,
    required this.distanceMeters,
    required this.duration,
  });

  final List<LatLng> path;
  final double distanceMeters;
  final Duration duration;
}

class _DecodedValue {
  const _DecodedValue({required this.value, required this.nextIndex});

  final int value;
  final int nextIndex;
}
