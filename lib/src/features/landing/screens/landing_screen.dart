import 'dart:async';

import 'package:TaxiApp/src/core/providers/taxi_routes_provider/taxi_routes_provider.dart';
import 'package:TaxiApp/src/core/widgets/loaders/generic_loader.dart';
import 'package:TaxiApp/src/features/landing/screens/landing_bottom_sheet.dart';
import 'package:TaxiApp/src/features/landing/screens/landing_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final TaxiRoutesProvider _taxiRoutesProvider = TaxiRoutesProvider.create();

  @override
  Widget build(BuildContext context) => Obx(() {
    if (_taxiRoutesProvider.isLoading.value) {
      return const Scaffold(body: Center(child: GenericLoader()));
    } else {
      return Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              mapTypeControlEnabled: true,
              initialCameraPosition:
                  _taxiRoutesProvider.userLocation.value != null
                  ? CameraPosition(
                      target: LatLng(
                        _taxiRoutesProvider.userLocation.value!.latitude,
                        _taxiRoutesProvider.userLocation.value!.longitude,
                      ),
                      zoom: 14.0,
                    )
                  : const CameraPosition(
                      target: LatLng(-25.790897377907932, 28.319562183317874),
                      zoom: 14.0,
                    ),
              compassEnabled: true,
              markers: _taxiRoutesProvider.nearbyRoutes
                  .map(
                    (route) => Marker(
                      markerId: MarkerId(route.routeId),
                      position: route.originPoint,
                    ),
                  )
                  .toSet(),
              myLocationButtonEnabled: true,
              trafficEnabled: true,
              buildingsEnabled: true,
              indoorViewEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              zoomControlsEnabled: false,
            ),
            LandingSearchBar(),
            LandingBottomSheet(),
          ],
        ),
      );
    }
  });
}
