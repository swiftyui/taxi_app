import 'package:TaxiApp/src/core/enums/action_type.dart';
import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/taxi_routes_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsProvider extends GetxController {
  MapsProvider();

  static MapsProvider create() => Get.isRegistered<MapsProvider>()
      ? Get.find<MapsProvider>()
      : Get.put<MapsProvider>(MapsProvider());

  final Rxn<GoogleMapController> mapController = Rxn<GoogleMapController>();

  final Set<Marker> markers = <Marker>{};
  final Set<Polyline> polylines = <Polyline>{};

  final RxInt mapVersion = 0.obs;

  final Rx<CameraPosition> initialCameraPosition = Rx<CameraPosition>(
    const CameraPosition(
      target: LatLng(-25.790897377907932, 28.319562183317874),
      zoom: 14.0,
    ),
  );

  Future<void> updateMarkers() async {
    final ActionsProvider actionsProvider = ActionsProvider.create();
    final TaxiRoutesProvider taxiRoutesProvider = TaxiRoutesProvider.create();
    Set<Marker> newMarkers;
    Set<Polyline> newPolylines;
    print(
      'Updating markers and polylines based on selected action: ${actionsProvider.selectedAction.value}',
    );

    switch (actionsProvider.selectedAction.value) {
      case ActionType.viewRoute:
        try {
          final route = actionsProvider.selectedRoute.value;
          print('Selected route for viewing: ${route?.routeId}');

          if (route == null) {
            newMarkers = <Marker>{};
            newPolylines = <Polyline>{};
            break;
          }

          final originMarker = Marker(
            markerId: MarkerId(route.routeId),
            position: route.originPoint,
          );

          final destinationMarker = Marker(
            markerId: MarkerId('${route.routeId}_destination'),
            position: route.destinationPoint,
          );

          newMarkers = {originMarker, destinationMarker};

          newPolylines = {
            Polyline(
              polylineId: PolylineId(route.routeId),
              points: route.model.geometry.coordinates
                  .map((coord) => LatLng(coord[1], coord[0]))
                  .toList(),
              color: Colors.blue,
              width: 5,
            ),
          };
          print('New polylines: $newPolylines');
          break;
        } catch (e) {
          print('Error creating markers or polylines for viewRoute: $e');
          newMarkers = <Marker>{};
          newPolylines = <Polyline>{};
        }

      default:
        newMarkers = {
          for (final route in taxiRoutesProvider.nearbyRoutes)
            Marker(
              markerId: MarkerId(route.routeId),
              position: route.originPoint,
              onTap: () {
                actionsProvider.setSelectedRoute(route);
              },
            ),
        };

        newPolylines = {};
    }

    markers
      ..clear()
      ..addAll(newMarkers);
    polylines
      ..clear()
      ..addAll(newPolylines);

    // Explicitly tell GetX to rebuild the GoogleMap.
    mapVersion.value++;

    // Wait for the GoogleMap widget to be rebuilt.
    if (actionsProvider.selectedAction.value == ActionType.viewRoute) {
      final route = actionsProvider.selectedRoute.value;

      if (route != null) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _fitRoute(route);
        });
      }
    }
  }

  void _fitRoute(route) {
    final controller = mapController.value;

    if (controller == null) {
      return;
    }

    final origin = route.originPoint;
    final destination = route.destinationPoint;

    final southwest = LatLng(
      origin.latitude < destination.latitude
          ? origin.latitude
          : destination.latitude,
      origin.longitude < destination.longitude
          ? origin.longitude
          : destination.longitude,
    );

    final northeast = LatLng(
      origin.latitude > destination.latitude
          ? origin.latitude
          : destination.latitude,
      origin.longitude > destination.longitude
          ? origin.longitude
          : destination.longitude,
    );

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: southwest, northeast: northeast),
        100.0,
      ),
    );
  }
}
