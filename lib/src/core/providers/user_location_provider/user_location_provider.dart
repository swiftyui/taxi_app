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
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void onInit() {
    super.onInit();
    refreshLocation();
  }

  void _subscribeToLocationChanges() {
    if (_positionStreamSubscription != null) {
      return;
    }
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).listen(
          (Position position) {
            userLocation.value = position;
            errorMessage.value = null;
          },
          onError: (Object error) {
            errorMessage.value = 'Unable to update your current location.';
          },
        );
  }

  @override
  void onClose() {
    _positionStreamSubscription?.cancel();
    super.onClose();
  }

  Future<Position?> refreshLocation({bool requestPermission = false}) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage.value = 'Turn on location services to plan a journey.';
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        errorMessage.value =
            'Location permission is required to plan a journey.';
        return null;
      }
      if (permission == LocationPermission.deniedForever) {
        errorMessage.value =
            'Location permission is disabled. Enable it in device settings.';
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      userLocation.value = position;
      _subscribeToLocationChanges();
      return position;
    } catch (_) {
      errorMessage.value = 'Unable to determine your current location.';
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
