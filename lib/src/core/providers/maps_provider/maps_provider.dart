import 'dart:math' as math;

import 'package:TaxiApp/src/core/enums/action_type.dart';
import 'package:TaxiApp/src/core/models/taxi_journey.dart';
import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/taxi_routes_provider.dart';
import 'package:TaxiApp/src/core/providers/user_location_provider/user_location_provider.dart';
import 'package:TaxiApp/src/core/services/taxi_routing_service.dart';
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
  static const _previewOutline = Color(0xFF462880);
  static const _alternativeColor = Color(0xFFCAB2F5);
  static const _alternativeOutline = Color(0xFF9975D1);

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
  final List<HambaMapRouteBadge> routeBadges = [];
  double journeyPreviewPanelHeight = 0;

  Future<void> updateMarkers({bool fitCamera = true}) async {
    final actions = ActionsProvider.create();
    final routes = TaxiRoutesProvider.create();
    markers.clear();
    paths.clear();
    routeBadges.clear();
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
          final previewing =
              actions.selectedAction.value == ActionType.journeyReady;
          final options = previewing && actions.journeyOptions.isNotEmpty
              ? actions.journeyOptions.toList()
              : [journey];
          if (previewing) {
            for (final alternative in options) {
              if (alternative != journey) {
                paths.addAll(alternative.steps.map(_alternativePath));
              }
            }
          }
          markers.addAll([
            for (var i = 0; i < journey.taxiLegs.length; i++) ...[
              HambaMapMarker(
                position: journey.taxiLegs[i].boardingPoint,
                label: i == 0 ? 'Board taxi' : 'Board connecting taxi',
                color: previewing ? Colours.journeyPurple : _taxiColor,
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
              color: previewing ? _previewOutline : Colours.red,
            ),
          ]);
          paths.addAll([
            for (var i = 0; i < journey.steps.length; i++)
              HambaMapPath(
                points: journey.steps[i].path,
                color:
                    previewing && journey.steps[i].type == JourneyStepType.taxi
                    ? Colours.journeyPurple
                    : _stepColor(journey.steps[i], i, actions),
                width:
                    previewing && journey.steps[i].type == JourneyStepType.taxi
                    ? 8
                    : _stepWidth(journey.steps[i], i, actions),
                borderColor:
                    previewing && journey.steps[i].type == JourneyStepType.taxi
                    ? _previewOutline
                    : Colors.white,
                borderWidth:
                    previewing && journey.steps[i].type == JourneyStepType.taxi
                    ? 2.5
                    : null,
                dashed: journey.steps[i].type != JourneyStepType.taxi,
              ),
          ]);
          if (fitCamera) {
            _fitJourney(journey, options, previewing: previewing);
          }
          if (previewing) {
            _addRouteBadges(journey, options, actions);
          }
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

  HambaMapPath _alternativePath(JourneyStep step) {
    final walking = step.type != JourneyStepType.taxi;
    return HambaMapPath(
      points: step.path,
      color: walking ? const Color(0xFFA48CB8) : _alternativeColor,
      width: walking ? 3 : 5,
      borderColor: walking ? Colors.white : _alternativeOutline,
      borderWidth: 2,
      dashed: walking,
    );
  }

  void _addRouteBadges(
    TaxiJourney selected,
    List<TaxiJourney> options,
    ActionsProvider actions,
  ) {
    final camera = mapController.camera;
    final size = camera.nonRotatedSize;
    final mapArea = Rect.fromLTRB(
      8,
      size.height * .18,
      size.width - 8,
      math.min(size.height * .84, size.height - journeyPreviewPanelHeight - 8),
    );
    final occupiedAreas = [
      Rect.fromCenter(
        center: camera.latLngToScreenOffset(selected.origin),
        width: 38,
        height: 38,
      ),
      for (final marker in markers)
        Rect.fromCenter(
          center:
              camera.latLngToScreenOffset(marker.position) -
              const Offset(0, 16),
          width: 38,
          height: 42,
        ),
    ];
    final badges = <HambaMapRouteBadge>[];
    for (final (index, option) in options.indexed) {
      final leg = option.taxiLegs.reduce(
        (first, second) =>
            first.distanceMeters >= second.distanceMeters ? first : second,
      );
      final anchors = [
        for (final fraction in [0.52, 0.35, 0.68, 0.24, 0.79, 0.14, 0.88])
          _pointAlongLeg(leg, fraction),
      ];
      final isSelected = option == selected;
      final width = isSelected ? 111.0 : 89.0;
      final height = isSelected ? 51.0 : 39.0;
      final preferredSide = index.isOdd;
      (LatLng, bool, Rect, double)? best;

      // Try both sides of each anchor. Horizontal separation alone can hide
      // the label underneath another callout even when the anchors are apart.
      for (final (rank, point) in anchors.indexed) {
        final screenPoint = camera.latLngToScreenOffset(point);
        for (final above in [preferredSide, !preferredSide]) {
          final area = Rect.fromCenter(
            center: screenPoint.translate(0, above ? -height / 2 : height / 2),
            width: width,
            height: height,
          ).inflate(5);
          final obscured = occupiedAreas.fold<double>(
            0,
            (total, occupied) => total + _area(area.intersect(occupied)),
          );
          final clipped = _area(area) - _area(area.intersect(mapArea));
          final score =
              obscured +
              clipped * 2 +
              rank * 12 +
              (above == preferredSide ? 0 : 9);
          if (best == null || score < best.$4) {
            best = (point, above, area, score);
          }
        }
      }
      final (point, above, area, _) = best!;
      occupiedAreas.add(area);
      badges.add(
        HambaMapRouteBadge(
          position: point,
          minutes: option.estimatedTravelMinutes,
          optionNumber: index + 1,
          selected: isSelected,
          recommended: index == 0,
          aboveRoute: above,
          onTap: () => actions.selectJourneyOption(option),
        ),
      );
    }
    // The selected label stays on top where routes converge.
    routeBadges.addAll(badges.where((badge) => !badge.selected));
    routeBadges.addAll(badges.where((badge) => badge.selected));
  }

  double _area(Rect rect) => rect.isEmpty ? 0 : rect.width * rect.height;

  LatLng _pointAlongLeg(TaxiJourneyLeg leg, double fraction) {
    final points = leg.routePoints;
    final target = fraction * leg.distanceMeters;
    var distance = 0.0;
    for (var index = 1; index < points.length; index++) {
      final from = points[index - 1];
      final to = points[index];
      final segment = TaxiRoutingService.distanceBetween(from, to);
      if (segment > 0 && distance + segment >= target) {
        final t = (target - distance) / segment;
        return LatLng(
          from.latitude + (to.latitude - from.latitude) * t,
          from.longitude + (to.longitude - from.longitude) * t,
        );
      }
      distance += segment;
    }
    return points.last;
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

  void _fitJourney(
    TaxiJourney journey,
    List<TaxiJourney> options, {
    required bool previewing,
  }) {
    final user = UserLocationProvider.create().userLocation.value;
    _fitPoints([
      if (user != null) LatLng(user.latitude, user.longitude),
      for (final option in options)
        for (final step in option.steps) ...step.path,
      journey.destination.position,
    ], bottomPadding: previewing ? journeyPreviewPanelHeight + 16 : 0);
  }

  void _fitPoints(List<LatLng> points, {double bottomPadding = 0}) {
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
        padding: EdgeInsets.fromLTRB(
          48,
          height * .17,
          48,
          math.max(height * .19, math.min(bottomPadding, height * .72)),
        ),
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
