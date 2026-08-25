import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class UserLocationProvider extends GetxController {
  UserLocationProvider();
  static UserLocationProvider create() =>
      Get.isRegistered<UserLocationProvider>()
      ? Get.find<UserLocationProvider>()
      : Get.put<UserLocationProvider>(UserLocationProvider());
  final Rxn<Position> userLocation = Rxn<Position>();
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void onInit() {
    super.onInit();
    _getCurrentLocation().then((position) {
      if (position != null) {
        userLocation.value = position;
      }
    });
    _positionStreamSubscription = _subscribeToLocationChanges();
  }

  StreamSubscription<Position>? _subscribeToLocationChanges() {
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).listen((Position position) {
          userLocation.value = position;
        });
    return _positionStreamSubscription;
  }

  @override
  void onClose() {
    _positionStreamSubscription?.cancel();
    super.onClose();
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
