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
  final MapsProvider _mapsProvider = MapsProvider.create();
  final UserLocationProvider _userLocationProvider =
      UserLocationProvider.create();
  late final Worker _locationWorker;
  bool _mapReady = false;
  bool _centeredOnInitialLocation = false;

  @override
  void initState() {
    super.initState();
    _locationWorker = ever(
      _userLocationProvider.userLocation,
      (_) => _centerOnInitialLocation(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mapsProvider.journeyPreviewPanelHeight = JourneyPreviewHeader.heightFor(
      context,
    );
  }

  void _centerOnInitialLocation() {
    if (!_mapReady ||
        _centeredOnInitialLocation ||
        _userLocationProvider.userLocation.value == null) {
      return;
    }
    _centeredOnInitialLocation = true;
    _mapsProvider.moveToMyLocation();
  }

  @override
  void dispose() {
    _locationWorker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    _mapsProvider.mapVersion.value;
    final location = _userLocationProvider.userLocation.value;
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
            showAttribution: false,
            userLocation: location == null
                ? null
                : LatLng(location.latitude, location.longitude),
            onReady: () {
              _mapReady = true;
              _centerOnInitialLocation();
            },
          ),
          LandingBottomSheet(),
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: LandingSearchBar()),
                        MyLocationButton().paddingOnly(left: Dimensions.eight),
                      ],
                    ),
                    const SizedBox(height: Dimensions.eight),
                    const OsmAttribution(includeVectorCredits: true),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
