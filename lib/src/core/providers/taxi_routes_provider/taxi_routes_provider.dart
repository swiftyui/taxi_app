// https://pta-gis-2-web1.csir.co.za/server2/rest/services/Hosted/Tshwane_Taxi_Routes_shp/FeatureServer/0/query?where=1%3D1&outFields=*&returnGeometry=true&f=geojson
import 'dart:async';
import 'dart:convert';

import 'package:TaxiApp/src/core/providers/maps_provider/maps_provider.dart';
import 'package:TaxiApp/src/core/models/driver_profile.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/nearby_taxi_route_model.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:TaxiApp/src/core/providers/user_location_provider/user_location_provider.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TaxiRoutesProvider extends GetxController {
  TaxiRoutesProvider(
    this._mapsProvider,
    this._userLocationProvider, {
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;
  static TaxiRoutesProvider create() => Get.isRegistered<TaxiRoutesProvider>()
      ? Get.find<TaxiRoutesProvider>()
      : Get.put<TaxiRoutesProvider>(
          TaxiRoutesProvider(
            MapsProvider.create(),
            UserLocationProvider.create(),
          ),
        );

  final MapsProvider _mapsProvider;
  final UserLocationProvider _userLocationProvider;
  final FirebaseFirestore _firestore;
  final List<TaxiRouteModel> _datasetRoutes = [];
  final List<TaxiRouteModel> _driverRoutes = [];
  final RxList<TaxiRouteModel> taxiRoutes = <TaxiRouteModel>[].obs;
  final RxList<NearbyTaxiRouteModel> nearbyRoutes =
      <NearbyTaxiRouteModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();
  late final Worker _locationWorker;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _driverRoutesSubscription;
  Position? _lastNearbyLocation;

  @override
  void onInit() {
    super.onInit();
    _locationWorker = ever<Position?>(_userLocationProvider.userLocation, (
      position,
    ) {
      if (position != null) {
        _mapsProvider.initialCameraPosition.value = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14,
        );
        if (taxiRoutes.isNotEmpty) {
          _updateNearbyRoutes(position);
        }
      }
    });
    _driverRoutesSubscription = _firestore
        .collectionGroup('driverRoutes')
        .snapshots()
        .listen(
          _handleDriverRoutes,
          onError: (Object error, StackTrace stackTrace) {
            debugPrint(
              'Unable to load public driver routes: $error\n$stackTrace',
            );
          },
        );
    unawaited(loadRoutes());
  }

  @override
  void onClose() {
    _locationWorker.dispose();
    _driverRoutesSubscription?.cancel();
    super.onClose();
  }

  Future<void> loadRoutes() async {
    if (isLoading.value) {
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;
      final url = Uri.https(
        'pta-gis-2-web1.csir.co.za',
        '/server2/rest/services/Hosted/Tshwane_Taxi_Routes_shp/FeatureServer/0/query',
        {
          'where': '1=1',
          'outFields': '*',
          'returnGeometry': 'true',
          'f': 'geojson',
        },
      );

      final response = await get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ClientException(
          'Taxi route request failed with status ${response.statusCode}.',
          url,
        );
      }

      final taxiRoutesData = TaxiRouteParent.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      _datasetRoutes
        ..clear()
        ..addAll(taxiRoutesData.features);
      _publishRoutes();

      final userLocation = _userLocationProvider.userLocation.value;
      if (userLocation != null) {
        _mapsProvider.initialCameraPosition.value = CameraPosition(
          target: LatLng(userLocation.latitude, userLocation.longitude),
          zoom: 14,
        );
        _lastNearbyLocation = userLocation;
        _findNearbyRoutes(userLocation);
      }

      await _mapsProvider.updateMarkers();
    } on TimeoutException {
      errorMessage.value = 'Taxi routes took too long to load. Please retry.';
    } on FormatException {
      errorMessage.value = 'Taxi route data could not be read.';
    } on ClientException {
      errorMessage.value =
          'Taxi routes are unavailable. Check your connection.';
    } catch (_) {
      errorMessage.value = 'Taxi routes could not be loaded.';
    } finally {
      isLoading.value = false;
    }
  }

  void _handleDriverRoutes(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _driverRoutes
      ..clear()
      ..addAll(
        snapshot.docs.map((document) {
          final route = DriverRoute.fromJson(document.id, document.data());
          return TaxiRouteModel.fromDriverRoute(route);
        }),
      );
    _publishRoutes();
    final userLocation = _userLocationProvider.userLocation.value;
    if (userLocation != null) {
      _findNearbyRoutes(userLocation);
      unawaited(_mapsProvider.updateMarkers());
    }
  }

  void _publishRoutes() {
    taxiRoutes.assignAll([..._datasetRoutes, ..._driverRoutes]);
  }

  void _updateNearbyRoutes(Position position) {
    final previousLocation = _lastNearbyLocation;
    if (previousLocation != null &&
        Geolocator.distanceBetween(
              previousLocation.latitude,
              previousLocation.longitude,
              position.latitude,
              position.longitude,
            ) <
            250) {
      return;
    }

    _lastNearbyLocation = position;
    _findNearbyRoutes(position);
    unawaited(_mapsProvider.updateMarkers());
  }

  void _findNearbyRoutes(Position userLocation) {
    nearbyRoutes.clear();
    List<TaxiRouteModel> internalTaxiRoutes = <TaxiRouteModel>[];

    for (final route in taxiRoutes) {
      // does the route have a coordinate inside a 5km radius of the user location
      if (route.geometry.coordinates.isEmpty) {
        continue;
      }

      for (final coordinate in route.geometry.coordinates) {
        final routeLatLng = LatLng(coordinate[1], coordinate[0]);
        final distanceInMeters = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          routeLatLng.latitude,
          routeLatLng.longitude,
        );

        if (distanceInMeters <= 5000) {
          internalTaxiRoutes.add(route);
          break; // No need to check other coordinates for this route
        }
      }
    }

    for (final route in internalTaxiRoutes) {
      final originCoordinates = route.geometry.coordinates.isNotEmpty
          ? LatLng(
              route.geometry.coordinates.first[1],
              route.geometry.coordinates.first[0],
            )
          : null;
      if (originCoordinates == null) {
        continue; // Skip this route if origin coordinates are not available
      }

      final destinationCoordinates = route.geometry.coordinates.length > 1
          ? LatLng(
              route.geometry.coordinates.last[1],
              route.geometry.coordinates.last[0],
            )
          : null;
      if (destinationCoordinates == null) {
        continue; // Skip this route if destination coordinates are not available
      }
      nearbyRoutes.add(
        NearbyTaxiRouteModel(
          routeId: route.properties.route_id,
          originPoint: originCoordinates,
          destinationPoint: destinationCoordinates,
          originName: route.properties.originname,
          destinationName: route.properties.destname,
          model: route,
        ),
      );
    }
  }
}
