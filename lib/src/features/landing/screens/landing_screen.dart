import 'package:TaxiApp/src/core/providers/maps_provider/maps_provider.dart';
import 'package:TaxiApp/src/core/providers/user_location_provider/user_location_provider.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/features/landing/screens/landing_bottom_sheet.dart';
import 'package:TaxiApp/src/features/landing/screens/landing_search_bar.dart';
import 'package:TaxiApp/src/features/landing/widgets/my_location_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final MapsProvider _mapsProvider = MapsProvider.create();
  final UserLocationProvider _userLocationProvider =
      UserLocationProvider.create();

  @override
  Widget build(BuildContext context) => Obx(() {
    _mapsProvider.mapVersion.value;
    final hasLocation = _userLocationProvider.userLocation.value != null;
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            mapTypeControlEnabled: true,
            initialCameraPosition: _mapsProvider.initialCameraPosition.value,
            compassEnabled: true,
            markers: _mapsProvider.markers,
            myLocationButtonEnabled: false,
            myLocationEnabled: hasLocation,
            trafficEnabled: true,
            buildingsEnabled: true,
            indoorViewEnabled: true,
            polylines: _mapsProvider.polylines,
            onMapCreated: (GoogleMapController controller) {
              _mapsProvider.mapController.value = controller;
              if (hasLocation) {
                _mapsProvider.moveToMyLocation();
              }
            },
            zoomControlsEnabled: false,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child:
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(child: LandingSearchBar()),
                      MyLocationButton().paddingOnly(left: Dimensions.eight),
                    ],
                  ).paddingOnly(
                    left: Dimensions.sixteen,
                    right: Dimensions.sixteen,
                    top: Dimensions.sixteen,
                  ),
            ),
          ),
          LandingBottomSheet(),
        ],
      ),
    );
  });
}
