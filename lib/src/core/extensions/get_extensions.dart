import 'package:TaxiApp/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

extension GetExtensions on GetInterface {
  ColorScheme get colorScheme => Theme.of(Get.context!).colorScheme;
  AppLocalizations get appLocalizations => AppLocalizations.of(context!);
}
