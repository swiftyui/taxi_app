// https://pta-gis-2-web1.csir.co.za/server2/rest/services/Hosted/Tshwane_Taxi_Routes_shp/FeatureServer/0/query?where=1%3D1&outFields=*&returnGeometry=true&f=geojson
import 'dart:convert';

import 'package:TaxiApp/src/core/providers/maps_provider/maps_provider.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/nearby_taxi_route_model.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:TaxiApp/src/core/providers/user_location_provider/user_location_provider.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TaxiRoutesProvider extends GetxController {
  TaxiRoutesProvider(this._mapsProvider);
  static TaxiRoutesProvider create() => Get.isRegistered<TaxiRoutesProvider>()
      ? Get.find<TaxiRoutesProvider>()
      : Get.put<TaxiRoutesProvider>(TaxiRoutesProvider(MapsProvider.create()));

  final MapsProvider _mapsProvider;
  final RxList<TaxiRouteParent> _taxiRoutesFeature = <TaxiRouteParent>[].obs;
  final RxList<TaxiRouteModel> taxiRoutes = <TaxiRouteModel>[].obs;
  final RxList<NearbyTaxiRouteModel> nearbyRoutes =
      <NearbyTaxiRouteModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _getPretoriaRoutes();
  }

  Future<void> _getPretoriaRoutes() async {
    try {
      isLoading.value = true;
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

      final response = await get(url);

      final data = response.body;

      final taxiRoutesData = TaxiRouteParent.fromJson(jsonDecode(data));

      _taxiRoutesFeature.value = [taxiRoutesData];
      taxiRoutes.value = taxiRoutesData.features;

      final UserLocationProvider userLocationProvider =
          UserLocationProvider.create();

      // Get user's current location

      while (userLocationProvider.userLocation.value == null) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Find nearby routes
      await _findNearbyRoutes(userLocationProvider.userLocation.value!);
      _mapsProvider.updateMarkers();
      _mapsProvider.initialCameraPosition.value = CameraPosition(
        target: LatLng(
          userLocationProvider.userLocation.value!.latitude,
          userLocationProvider.userLocation.value!.longitude,
        ),
        zoom: 14.0,
      );
    } catch (e) {
      print('Error fetching Pretoria Taxi Routes: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _findNearbyRoutes(Position userLocation) async {
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
