import 'package:TaxiApp/src/core/providers/maps_provider/maps_provider.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:flutter/material.dart';

class MyLocationButton extends StatelessWidget {
  MyLocationButton({super.key});

  final MapsProvider mapsProvider = MapsProvider.create();

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 3,
    shadowColor: Colours.primaryOne.withValues(alpha: .3),
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: SizedBox.square(
      dimension: 50,
      child: IconButton(
        onPressed: mapsProvider.moveToMyLocation,
        tooltip: 'My location',
        icon: const Icon(Icons.my_location_rounded, color: Colours.blueThree),
      ),
    ),
  );
}
