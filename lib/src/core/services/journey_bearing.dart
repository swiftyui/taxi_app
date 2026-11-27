import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class JourneyBearing {
  static const _distance = Distance(roundResult: false);
  static const _minimumMovement = 8.0;
  static const _maximumCourseError = 35.0;
  static const _turnThreshold = 6.0;

  Position? _movementAnchor;
  double? _bearing;

  double? update(Position position, {Iterable<LatLng> route = const []}) {
    final course = _reportedCourse(position) ?? _courseFromMovement(position);
    if (course != null || _movementAnchor == null) {
      _movementAnchor = position;
    }

    final previous = _bearing;
    final candidate =
        course ?? (previous == null ? _directionOfRoute(route) : null);
    if (candidate != null &&
        (previous == null ||
            ((candidate - previous + 180) % 360 - 180).abs() >=
                _turnThreshold)) {
      _bearing = candidate % 360;
    }
    return _bearing;
  }

  double? _reportedCourse(Position position) {
    if (position.speed >= 0.8 &&
        position.heading >= 0 &&
        position.heading < 360 &&
        position.headingAccuracy >= 0 &&
        position.headingAccuracy <= _maximumCourseError &&
        (position.heading != 0 || position.headingAccuracy > 0)) {
      return position.heading;
    }
    return null;
  }

  double? _courseFromMovement(Position position) {
    final anchor = _movementAnchor;
    if (anchor == null || !position.timestamp.isAfter(anchor.timestamp)) {
      return null;
    }
    final minimumDistance = math.max(
      _minimumMovement,
      math.max(anchor.accuracy, position.accuracy),
    );
    final from = LatLng(anchor.latitude, anchor.longitude);
    final to = LatLng(position.latitude, position.longitude);
    if (_distance.as(LengthUnit.Meter, from, to) < minimumDistance) {
      return null;
    }
    return _distance.bearing(from, to);
  }

  double? _directionOfRoute(Iterable<LatLng> route) {
    LatLng? start;
    for (final point in route) {
      start ??= point;
      if (_distance.as(LengthUnit.Meter, start, point) >= _minimumMovement) {
        return _distance.bearing(start, point);
      }
    }
    return null;
  }
}
