import 'package:TaxiApp/src/core/providers/maps_provider/maps_provider.dart';
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
  final TaxiRoutesProvider _taxiRoutesProvider = TaxiRoutesProvider.create();
  final MapsProvider _mapsProvider = MapsProvider.create();

  @override
  Widget build(BuildContext context) => Obx(() {
    if (_taxiRoutesProvider.isLoading.value) {
      return const Scaffold(body: Center(child: GenericLoader()));
    } else {
      final version = _mapsProvider.mapVersion.value;
      return Scaffold(
        body: Stack(
          children: [
            Obx(
              () => GoogleMap(
                key: ValueKey(version),
                mapTypeControlEnabled: true,
                initialCameraPosition:
                    _mapsProvider.initialCameraPosition.value,
                compassEnabled: true,
                markers: _mapsProvider.markers,
                myLocationButtonEnabled: true,
                trafficEnabled: true,
                buildingsEnabled: true,
                indoorViewEnabled: true,
                polylines: _mapsProvider.polylines,
                onMapCreated: (GoogleMapController controller) =>
                    _mapsProvider.mapController.value = controller,
                zoomControlsEnabled: false,
              ),
            ),
            const LandingSearchBar(),
            LandingBottomSheet(),
          ],
        ),
      );
    }
  });
}
