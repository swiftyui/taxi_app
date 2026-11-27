import 'package:TaxiApp/src/core/services/journey_bearing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('starts along the route and holds its direction through GPS drift', () {
    final bearing = JourneyBearing();
    expect(
      bearing.update(
        _fix(heading: 180),
        route: const [LatLng(0, 0), LatLng(0, 0), LatLng(0, .001)],
      ),
      closeTo(90, .1),
    );
    expect(bearing.update(_fix(second: 1, latitude: .00005)), closeTo(90, .1));
  });

  test(
    'finds the direction from reliable displacement without a GPS course',
    () {
      final bearing = JourneyBearing();
      expect(bearing.update(_fix()), isNull);
      expect(
        bearing.update(_fix(second: 1, longitude: -.0002, speed: 1)),
        closeTo(270, .1),
      );
      expect(
        bearing.update(
          _fix(
            second: 2,
            longitude: -.0002,
            latitude: .0002,
            heading: 90,
            headingAccuracy: 60,
            speed: 1,
          ),
        ),
        closeTo(0, .1),
      );
    },
  );

  test('accepts a turn and ignores small changes across north', () {
    final bearing = JourneyBearing();
    expect(bearing.update(_fix(heading: 359, speed: 4)), 359);
    expect(bearing.update(_fix(second: 1, heading: 2, speed: 4)), 359);
    expect(bearing.update(_fix(second: 2, heading: 80, speed: 4)), 80);
    expect(
      bearing.update(_fix(second: 3, heading: 0, headingAccuracy: 5, speed: 4)),
      0,
    );
  });
}

Position _fix({
  int second = 0,
  double latitude = 0,
  double longitude = 0,
  double heading = 0,
  double headingAccuracy = 0,
  double speed = 0,
}) => Position(
  latitude: latitude,
  longitude: longitude,
  timestamp: DateTime.utc(2026, 1, 1, 0, 0, second),
  accuracy: 10,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: heading,
  headingAccuracy: headingAccuracy,
  speed: speed,
  speedAccuracy: 0,
);
