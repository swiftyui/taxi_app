import 'package:TaxiApp/src/core/enums/image_list.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glowy_borders/glowy_borders.dart';

class GenericLoader extends StatelessWidget {
  const GenericLoader({super.key});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Center(
        child: AnimatedGradientBorder(
          borderRadius: BorderRadius.circular(999),
          borderSize: 2,
          glowSize: 10,
          gradientColors: [
            Colours.red,
            Colours.yellow,
            Colours.green,
            Colors.black,
          ],
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colours.primaryOne.withValues(alpha: 0.6),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: SvgPicture.asset(ImageList.appLogo, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    ],
  );
}
