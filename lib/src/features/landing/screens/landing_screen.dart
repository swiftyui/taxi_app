import 'package:TaxiApp/src/core/widgets/app_bars/custom_app_bar.dart';
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
    appBar: CustomAppBar(),
    body: GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(0, 0),
        zoom: 2,
      ),
    ),
  );
}
