import 'package:TaxiApp/src/core/enums/action_type.dart';
import 'package:TaxiApp/src/core/models/taxi_journey.dart';
import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/taxi_routes_provider.dart';
import 'package:TaxiApp/src/core/providers/user_location_provider/user_location_provider.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/widgets/hamba_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class MapsProvider extends GetxController {
  static const _taxiColor = Color(0xFF007A70);
  static const _walkEstimateColor = Color(0xFF43536B);
  static const _transferColor = Color(0xFF895918);

  static MapsProvider create() => Get.isRegistered<MapsProvider>()
      ? Get.find<MapsProvider>()
      : Get.put<MapsProvider>(MapsProvider());

  final MapController mapController = MapController();
  final RxInt mapVersion = 0.obs;
  final Rx<LatLng> initialCenter = const LatLng(
    -25.7908973779,
    28.3195621833,
  ).obs;
  final RxDouble initialZoom = 14.0.obs;
  final List<HambaMapMarker> markers = [];
  final List<HambaMapPath> paths = [];

  Future<void> updateMarkers() async {
    final actions = ActionsProvider.create();
    final routes = TaxiRoutesProvider.create();
    markers.clear();
    paths.clear();
    switch (actions.selectedAction.value) {
      case ActionType.viewRoute:
        final route = actions.selectedRoute.value;
        if (route != null) {
          markers.addAll([
            HambaMapMarker(
              position: route.originPoint,
              label: 'Route start: ${route.originName}',
              color: _taxiColor,
              icon: Icons.directions_bus_rounded,
            ),
            HambaMapMarker(
              position: route.destinationPoint,
              label: 'Route end: ${route.destinationName}',
              icon: Icons.flag_rounded,
            ),
          ]);
          paths.addAll([
            for (final part in route.model.geometry.parts)
              if (part.length > 1)
                HambaMapPath(
                  points: part.map((c) => LatLng(c[1], c[0])).toList(),
                  color: _taxiColor,
                  width: 6.5,
                ),
          ]);
          _fitPoints(
            route.model.geometry.coordinates
                .map((c) => LatLng(c[1], c[0]))
                .toList(),
          );
        }
        break;
      case ActionType.planningJourney:
        final destination = actions.selectedDestination.value;
        if (destination != null) {
          markers.add(
            HambaMapMarker(
              position: destination.position,
              label: 'Destination: ${destination.label}',
              icon: Icons.flag_rounded,
            ),
          );
        }
        break;
      case ActionType.journeyReady:
      case ActionType.journeyStarted:
      case ActionType.journeyCompleted:
        final journey = actions.journey.value;
        if (journey != null) {
          markers.addAll([
            for (var i = 0; i < journey.taxiLegs.length; i++) ...[
              HambaMapMarker(
                position: journey.taxiLegs[i].boardingPoint,
                label: i == 0 ? 'Board taxi' : 'Board connecting taxi',
                color: _taxiColor,
                icon: Icons.directions_bus_rounded,
              ),
              HambaMapMarker(
                position: journey.taxiLegs[i].exitPoint,
                label: i == journey.taxiLegs.length - 1
                    ? 'Leave taxi'
                    : 'Transfer taxis',
                color: _transferColor,
                icon: i == journey.taxiLegs.length - 1
                    ? Icons.directions_walk_rounded
                    : Icons.swap_horiz_rounded,
                compact: true,
              ),
            ],
            HambaMapMarker(
              position: journey.destination.position,
              label: 'Destination: ${journey.destination.label}',
              icon: Icons.flag_rounded,
            ),
          ]);
          paths.addAll([
            for (var i = 0; i < journey.steps.length; i++)
              HambaMapPath(
                points: journey.steps[i].path,
                color: _stepColor(journey.steps[i], i, actions),
                width: _stepWidth(journey.steps[i], i, actions),
                dashed: journey.steps[i].type != JourneyStepType.taxi,
              ),
          ]);
          _fitJourney(journey);
        }
        break;
      default:
        markers.addAll([
          for (final route in routes.nearbyRoutes)
            HambaMapMarker(
              position: route.originPoint,
              label: '${route.originName} to ${route.destinationName}',
              color: Colours.primaryOne,
              icon: Icons.directions_bus_rounded,
              compact: true,
              onTap: () {
                actions.setSelectedRoute(route);
                actions.viewRoute(route);
              },
            ),
        ]);
        break;
    }
    mapVersion.value++;
  }

  Color _stepColor(JourneyStep step, int index, ActionsProvider actions) {
    if (actions.selectedAction.value == ActionType.journeyCompleted ||
        (actions.selectedAction.value == ActionType.journeyStarted &&
            index < actions.activeJourneyStepIndex.value)) {
      return const Color(0xFF7B8687);
    }
    if (actions.selectedAction.value == ActionType.journeyStarted &&
        index == actions.activeJourneyStepIndex.value) {
      return step.type == JourneyStepType.taxi
          ? const Color(0xFF004E48)
          : Colours.blue;
    }
    return step.type == JourneyStepType.taxi
        ? _taxiColor
        : step.hasMappedWalkingRoute
        ? Colours.blue
        : _walkEstimateColor;
  }

  double _stepWidth(JourneyStep step, int index, ActionsProvider actions) {
    final width = step.type == JourneyStepType.taxi ? 6.5 : 4.5;
    final active =
        actions.selectedAction.value == ActionType.journeyStarted &&
        index == actions.activeJourneyStepIndex.value;
    return active ? width + 1.5 : width;
  }

  void _fitJourney(TaxiJourney journey) {
    final user = UserLocationProvider.create().userLocation.value;
    _fitPoints([
      if (user != null) LatLng(user.latitude, user.longitude),
      for (final step in journey.steps) ...step.path,
      journey.destination.position,
    ]);
  }

  void _fitPoints(List<LatLng> points) {
    if (points.isEmpty) {
      return;
    }
    if (points.length == 1) {
      mapController.move(points.first, 15);
      return;
    }
    final height = mapController.camera.nonRotatedSize.height;
    mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        maxZoom: 17,
        padding: EdgeInsets.fromLTRB(48, height * .17, 48, height * .19),
      ),
    );
  }

  Future<void> moveToMyLocation() async {
    final location = UserLocationProvider.create();
    final position =
        location.userLocation.value ??
        await location.refreshLocation(requestPermission: true);
    if (position != null) {
      mapController.move(LatLng(position.latitude, position.longitude), 15);
    }
  }
}
