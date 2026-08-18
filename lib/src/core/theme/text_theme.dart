import 'package:TaxiApp/src/core/theme/constants/font_sizes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme getTextTheme({required ColorScheme colorScheme}) {
  final fontTextTheme = GoogleFonts.montserratTextTheme();
  return fontTextTheme.copyWith(
    headlineLarge: fontTextTheme.headlineLarge?.copyWith(
      color: colorScheme.primary,
      fontSize: FontSize.thirtySix,
    ),
    headlineMedium: fontTextTheme.headlineMedium?.copyWith(
      color: colorScheme.primary,
      fontSize: FontSize.thirtyFour,
    ),
    headlineSmall: fontTextTheme.headlineSmall?.copyWith(
      color: colorScheme.primary,
      fontSize: FontSize.thirtyTwo,
    ),
    displayLarge: fontTextTheme.displayLarge?.copyWith(
      color: colorScheme.primary,
      fontSize: FontSize.thirty,
    ),
    displayMedium: fontTextTheme.displayMedium?.copyWith(
      color: colorScheme.primary,
      fontSize: FontSize.twentyEight,
    ),
    displaySmall: fontTextTheme.displaySmall?.copyWith(
      color: colorScheme.primary,
      fontSize: FontSize.twentySix,
    ),
    titleLarge: fontTextTheme.titleLarge?.copyWith(
      color: colorScheme.primary,
      fontSize: FontSize.twentyFour,
    ),
    titleMedium: fontTextTheme.titleMedium?.copyWith(
      color: colorScheme.primary,
      fontSize: FontSize.twentyTwo,
    ),
    titleSmall: fontTextTheme.titleSmall?.copyWith(
      color: colorScheme.primary,
      fontSize: FontSize.twenty,
    ),
    bodyLarge: fontTextTheme.bodyLarge?.copyWith(
      color: colorScheme.primary,
      fontSize: FontSize.eighteen,
    ),
    bodyMedium: fontTextTheme.bodyMedium?.copyWith(
      color: colorScheme.primary,
      fontSize: FontSize.sixteen,
    ),
    bodySmall: fontTextTheme.bodySmall?.copyWith(
      color: colorScheme.primary,
      fontSize: FontSize.fourteen,
    ),
    labelLarge: fontTextTheme.labelLarge?.copyWith(
      color: colorScheme.primary,
      fontSize: FontSize.twelve,
    ),
    labelMedium: fontTextTheme.labelMedium?.copyWith(
      fontSize: FontSize.ten,
      color: colorScheme.primary,
    ),
    labelSmall: fontTextTheme.labelSmall?.copyWith(
      color: colorScheme.primary,
      fontSize: FontSize.eight,
    ),
  );
}
