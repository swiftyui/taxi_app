import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/theme/constants/font_sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AppBarTitleWidget extends StatelessWidget {
  const AppBarTitleWidget({
    required this.leading,
    required this.trailing,
    this.crossAxisAlignment,
    this.mainAxisAlignment,
    this.textColor,
    super.key,
  });

  final String leading;
  final String trailing;
  final CrossAxisAlignment? crossAxisAlignment;
  final MainAxisAlignment? mainAxisAlignment;
  final Color? textColor;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
    mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
    children: [
      Text(
        leading,
        style: GoogleFonts.poppins().copyWith(
          color: textColor ?? Get.theme.colorScheme.onSurface,
          fontWeight: FontWeight.w100,
          fontSize: FontSize.sixteen,
        ),
      ).paddingOnly(right: Dimensions.four),
      Text(
        trailing,
        style: GoogleFonts.poppins().copyWith(
          color: textColor ?? Get.theme.colorScheme.onSurface,
          fontSize: FontSize.sixteen,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}
