import 'package:TaxiApp/src/core/extensions/typed_extensions.dart';
import 'package:TaxiApp/src/core/providers/maps_provider/maps_provider.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyLocationButton extends StatelessWidget {
  MyLocationButton({super.key});

  final MapsProvider mapsProvider = MapsProvider.create();

  @override
  Widget build(BuildContext context) =>
      Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.pin_drop_rounded,
          color: Colours.primaryOne,
          size: 24,
        ).paddingAll(Dimensions.twelve),
      ).onTap(() {
        mapsProvider.moveToMyLocation();
      });
}
