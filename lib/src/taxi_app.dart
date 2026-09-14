import 'dart:io';
import 'package:TaxiApp/src/core/providers/language_provider/language_provider.dart';
import 'package:TaxiApp/src/core/routes/routes.dart';
import 'package:TaxiApp/src/core/theme/theme.dart';
import 'package:TaxiApp/src/l10n/app_localizations.dart';
import 'package:TaxiApp/src/features/ride_requests/widgets/ride_request_banner.dart';
import 'package:TaxiApp/src/features/driver_reviews/widgets/driver_review_prompt.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TaxiApp extends StatelessWidget {
  TaxiApp({super.key});

  final _languagePreferenceViewModelProvider = LanguageProvider.create();
  final _themeSettingsService = ThemeSettingsService.create();

  @override
  Widget build(BuildContext context) => GetMaterialApp(
    title: 'HambaGo',
    debugShowCheckedModeBanner: false,
    theme: _themeSettingsService.lightTheme(),
    darkTheme: _themeSettingsService.darkTheme(),
    themeMode: ThemeMode.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: _languagePreferenceViewModelProvider.locale.value,
    initialRoute: initialRoute,
    opaqueRoute: true,
    defaultTransition: Transition.rightToLeftWithFade,
    getPages: pages,
    builder: (context, child) => SafeArea(
      top: false,
      bottom: kIsWeb
          ? false
          : Platform.isAndroid
          ? true
          : false,
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.noScaling, boldText: false),
        // Ride requests must remain visible above every app route.
        child: Stack(
          children: [
            child!,
            const DriverReviewPromptHost(),
            Positioned(top: 0, left: 0, right: 0, child: RideRequestBanner()),
          ],
        ),
      ),
    ),
  );
}
