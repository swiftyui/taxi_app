import 'package:TaxiApp/src/core/enums/action_type.dart';
import 'package:TaxiApp/src/core/models/taxi_journey.dart';
import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/taxi_routes_provider.dart';
import 'package:TaxiApp/src/core/providers/user_location_provider/user_location_provider.dart';
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

    switch (actionsProvider.selectedAction.value) {
      case ActionType.viewRoute:
        try {
          final route = actionsProvider.selectedRoute.value;

          if (route == null) {
            newMarkers = <Marker>{};
            newPolylines = <Polyline>{};
            break;
          }

          final originMarker = Marker(
            markerId: MarkerId('route_${route.model.id}_origin'),
            position: route.originPoint,
          );

          final destinationMarker = Marker(
            markerId: MarkerId('route_${route.model.id}_destination'),
            position: route.destinationPoint,
          );

          newMarkers = {originMarker, destinationMarker};

          newPolylines = {
            for (
              var partIndex = 0;
              partIndex < route.model.geometry.parts.length;
              partIndex++
            )
              Polyline(
                polylineId: PolylineId('route_${route.model.id}_$partIndex'),
                points: route.model.geometry.parts[partIndex]
                    .map((coord) => LatLng(coord[1], coord[0]))
                    .toList(),
                color: Colors.blue,
                width: 5,
              ),
          };
          break;
        } catch (e) {
          newMarkers = <Marker>{};
          newPolylines = <Polyline>{};
        }

      case ActionType.planningJourney:
        final destination = actionsProvider.selectedDestination.value;
        newMarkers = destination == null
            ? <Marker>{}
            : {
                Marker(
                  markerId: const MarkerId('journey_destination'),
                  position: destination.position,
                  infoWindow: InfoWindow(title: destination.label),
                ),
              };
        newPolylines = <Polyline>{};

      case ActionType.journeyReady:
      case ActionType.journeyStarted:
        final journey = actionsProvider.journey.value;
        if (journey == null) {
          newMarkers = <Marker>{};
          newPolylines = <Polyline>{};
          break;
        }
        final currentPosition =
            UserLocationProvider.create().userLocation.value;
        final currentPoint = currentPosition == null
            ? journey.boardingPoint
            : LatLng(currentPosition.latitude, currentPosition.longitude);
        newMarkers = {
          Marker(
            markerId: const MarkerId('journey_boarding'),
            position: journey.boardingPoint,
            infoWindow: const InfoWindow(title: 'Board taxi'),
          ),
          Marker(
            markerId: const MarkerId('journey_exit'),
            position: journey.exitPoint,
            infoWindow: const InfoWindow(title: 'Leave taxi'),
          ),
          Marker(
            markerId: const MarkerId('journey_destination'),
            position: journey.destination.position,
            infoWindow: InfoWindow(title: journey.destination.label),
          ),
        };
        newPolylines = {
          Polyline(
            polylineId: const PolylineId('walk_to_taxi'),
            points: [currentPoint, journey.boardingPoint],
            color: Colors.blueGrey,
            width: 5,
            patterns: [PatternItem.dash(18), PatternItem.gap(10)],
          ),
          Polyline(
            polylineId: const PolylineId('taxi_journey'),
            points: journey.taxiRoutePoints,
            color: Colors.amber,
            width: 7,
          ),
          Polyline(
            polylineId: const PolylineId('walk_to_destination'),
            points: [journey.exitPoint, journey.destination.position],
            color: Colors.blueGrey,
            width: 5,
            patterns: [PatternItem.dash(18), PatternItem.gap(10)],
          ),
        };
        break;

      default:
        newMarkers = {
          for (final route in taxiRoutesProvider.nearbyRoutes)
            Marker(
              markerId: MarkerId('nearby_${route.model.id}'),
              position: route.originPoint,
              onTap: () async {
                actionsProvider.setSelectedRoute(route);
                actionsProvider.viewRoute(route);
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
    final selectedAction = actionsProvider.selectedAction.value;
    if (selectedAction == ActionType.viewRoute) {
      final route = actionsProvider.selectedRoute.value;
      if (route != null) {
        Future<void>.delayed(
          const Duration(milliseconds: 100),
          () => _fitPoints(
            route.model.geometry.coordinates
                .map((coordinate) => LatLng(coordinate[1], coordinate[0]))
                .toList(),
          ),
        );
      }
    } else if (selectedAction == ActionType.journeyReady ||
        selectedAction == ActionType.journeyStarted) {
      final journey = actionsProvider.journey.value;
      if (journey != null) {
        Future<void>.delayed(
          const Duration(milliseconds: 100),
          () => _fitJourney(journey),
        );
      }
    }
  }

  void _fitJourney(TaxiJourney journey) {
    final currentPosition = UserLocationProvider.create().userLocation.value;
    _fitPoints([
      if (currentPosition != null)
        LatLng(currentPosition.latitude, currentPosition.longitude),
      ...journey.taxiRoutePoints,
      journey.destination.position,
    ]);
  }

  void _fitPoints(List<LatLng> points) {
    final controller = mapController.value;

    if (controller == null || points.isEmpty) {
      return;
    }

    var minLatitude = points.first.latitude;
    var maxLatitude = points.first.latitude;
    var minLongitude = points.first.longitude;
    var maxLongitude = points.first.longitude;
    for (final point in points.skip(1)) {
      minLatitude = point.latitude < minLatitude ? point.latitude : minLatitude;
      maxLatitude = point.latitude > maxLatitude ? point.latitude : maxLatitude;
      minLongitude = point.longitude < minLongitude
          ? point.longitude
          : minLongitude;
      maxLongitude = point.longitude > maxLongitude
          ? point.longitude
          : maxLongitude;
    }

    if (minLatitude == maxLatitude && minLongitude == maxLongitude) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
      return;
    }

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLatitude, minLongitude),
          northeast: LatLng(maxLatitude, maxLongitude),
        ),
        100.0,
      ),
    );
  }

  Future<void> moveToMyLocation() async {
    final UserLocationProvider userLocationProvider =
        UserLocationProvider.create();
    final controller = mapController.value;

    final position =
        userLocationProvider.userLocation.value ??
        await userLocationProvider.refreshLocation(requestPermission: true);
    if (controller == null || position == null) {
      return;
    }
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        14.0,
      ),
    );
  }
}
