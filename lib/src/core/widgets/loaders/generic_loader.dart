import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/theme/constants/font_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class GenericLoader extends StatelessWidget {
  const GenericLoader({super.key});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SpinKitCircle(
        itemBuilder: (context, index) => DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index.isEven ? Colours.primaryTwo : Colours.primaryThree,
          ),
        ),
      ).paddingOnly(bottom: Dimensions.sixteen),
      Text(
        Get.appLocalizations.gettingThingsReady,
        style: GoogleFonts.pacifico().copyWith(
          color: Colours.charcoal,
          fontSize: FontSize.twentyFour,
          fontWeight: FontWeight.w100,
        ),
      ),
    ],
  );
}
