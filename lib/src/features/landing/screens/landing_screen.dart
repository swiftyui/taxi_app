import 'dart:math' as math;

import 'package:TaxiApp/src/core/enums/action_type.dart';
import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/providers/maps_provider/maps_provider.dart';
import 'package:TaxiApp/src/core/providers/user_location_provider/user_location_provider.dart';
import 'package:TaxiApp/src/core/widgets/hamba_map.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/features/landing/screens/landing_bottom_sheet.dart';
import 'package:TaxiApp/src/features/landing/screens/landing_search_bar.dart';
import 'package:TaxiApp/src/features/landing/widgets/journey_details_widget.dart';
import 'package:TaxiApp/src/features/landing/widgets/my_location_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ActionsProvider _actionsProvider = ActionsProvider.create();
  final MapsProvider _mapsProvider = MapsProvider.create();
  final UserLocationProvider _userLocationProvider =
      UserLocationProvider.create();
  late final Worker _locationWorker;
  late final Worker _actionWorker;
  bool _mapReady = false;
  bool _centeredOnInitialLocation = false;

  @override
  void initState() {
    super.initState();
    _locationWorker = ever(_userLocationProvider.userLocation, (_) {
      _centerOnInitialLocation();
      if (_mapReady) {
        _mapsProvider.updateJourneyLocation();
      }
    });
    _actionWorker = ever(_actionsProvider.selectedAction, _updateJourneyCamera);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mapsProvider.journeyPreviewPanelHeight = JourneyPreviewHeader.heightFor(
      context,
    );
    _mapsProvider.journeyGuidancePanelHeight = JourneyGuidanceHeader.heightFor(
      context,
    );
  }

  void _updateJourneyCamera(ActionType? action) {
    if (!_mapReady) {
      return;
    }
    if (action == ActionType.journeyStarted) {
      // The first progress update can skip a pickup leg that is already complete.
      Future<void>.microtask(() {
        if (mounted && _actionsProvider.selectedAction.value == action) {
          _mapsProvider.startFollowingJourney();
        }
      });
    } else {
      _mapsProvider.endJourneyCamera();
    }
  }

  void _centerOnInitialLocation() {
    if (!_mapReady ||
        _centeredOnInitialLocation ||
        _userLocationProvider.userLocation.value == null) {
      return;
    }
    _centeredOnInitialLocation = true;
    if (_actionsProvider.selectedAction.value != ActionType.journeyStarted) {
      _mapsProvider.moveToMyLocation();
    }
  }

  bool _onJourneySheetResized(DraggableScrollableNotification notification) {
    if (notification.depth == 0 &&
        _mapReady &&
        _actionsProvider.selectedAction.value == ActionType.journeyStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _actionsProvider.selectedAction.value ==
                ActionType.journeyStarted) {
          _mapsProvider.updateJourneyPanelExtent(notification.extent);
        }
      });
    }
    return false;
  }

  @override
  void dispose() {
    _locationWorker.dispose();
    _actionWorker.dispose();
    _mapsProvider.stopFollowingJourney();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    _mapsProvider.mapVersion.value;
    final location = _userLocationProvider.userLocation.value;
    final guiding =
        _actionsProvider.selectedAction.value == ActionType.journeyStarted;
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          HambaMap(
            controller: _mapsProvider.mapController,
            center: _mapsProvider.initialCenter.value,
            zoom: _mapsProvider.initialZoom.value,
            markers: _mapsProvider.markers,
            paths: _mapsProvider.paths,
            routeBadges: _mapsProvider.routeBadges,
            locationBearing: guiding
                ? _mapsProvider.journeyBearing.value ?? 0
                : null,
            showAttribution: false,
            userLocation: location == null
                ? null
                : LatLng(location.latitude, location.longitude),
            onReady: () {
              _mapReady = true;
              _mapsProvider.updateJourneyPanelExtent(0);
              _centerOnInitialLocation();
              _updateJourneyCamera(_actionsProvider.selectedAction.value);
            },
            onMapGesture: _mapsProvider.stopFollowingJourney,
          ),
          Positioned.fill(
            child: CustomMultiChildLayout(
              delegate: _LandingMapOverlayLayout(MediaQuery.paddingOf(context)),
              children: [
                LayoutId(
                  id: _LandingMapOverlay.panel,
                  child: NotificationListener<DraggableScrollableNotification>(
                    onNotification: _onJourneySheetResized,
                    child: LandingBottomSheet(),
                  ),
                ),
                LayoutId(
                  id: _LandingMapOverlay.controls,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          const Expanded(child: LandingSearchBar()),
                          MyLocationButton().paddingOnly(
                            left: Dimensions.eight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                LayoutId(
                  id: _LandingMapOverlay.credits,
                  child: const OsmAttribution(includeVectorCredits: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  });
}

enum _LandingMapOverlay { panel, controls, credits }

class _LandingMapOverlayLayout extends MultiChildLayoutDelegate {
  _LandingMapOverlayLayout(this.safePadding);

  final EdgeInsets safePadding;

  @override
  void performLayout(Size size) {
    final fullWidth = BoxConstraints(
      minWidth: size.width,
      maxWidth: size.width,
      maxHeight: size.height,
    );
    final panel = layoutChild(_LandingMapOverlay.panel, fullWidth);
    final panelTop = size.height - panel.height;
    positionChild(_LandingMapOverlay.panel, Offset(0, panelTop));

    final controls = layoutChild(_LandingMapOverlay.controls, fullWidth);
    positionChild(_LandingMapOverlay.controls, Offset.zero);

    const inset = 16.0;
    final credits = layoutChild(
      _LandingMapOverlay.credits,
      BoxConstraints.loose(
        Size(
          math.max(0.0, size.width - safePadding.horizontal - 2 * inset),
          size.height,
        ),
      ),
    );
    final bottomAlignedTop = panelTop - credits.height;
    final creditTop = bottomAlignedTop >= controls.height
        ? math.max(controls.height, bottomAlignedTop - 6)
        // A tall panel can leave too little space below the top controls.
        : safePadding.top;
    positionChild(
      _LandingMapOverlay.credits,
      Offset(size.width - safePadding.right - inset - credits.width, creditTop),
    );
  }

  @override
  bool shouldRelayout(_LandingMapOverlayLayout oldDelegate) =>
      safePadding != oldDelegate.safePadding;
}
