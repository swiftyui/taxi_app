import 'package:TaxiApp/src/features/landing/screens/landing_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        const GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(-25.7479, 28.2293),
            zoom: 12,
          ),
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
        ),
        LandingBottomSheet(),
      ],
    ),
  );
}
