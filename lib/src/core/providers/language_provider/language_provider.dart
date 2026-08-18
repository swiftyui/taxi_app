import 'package:TaxiApp/src/core/providers/shared_preferences/enums/shared_preference_key.dart';
import 'package:TaxiApp/src/core/providers/shared_preferences/shared_preference_manager.dart';
import 'package:TaxiApp/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LanguageProvider extends GetxController {
  final locale = Rx<Locale>(const Locale('en'));
  final _sharedPreferences = SharedPreferencesManager();

  static LanguageProvider create() => Get.isRegistered<LanguageProvider>()
      ? Get.find<LanguageProvider>()
      : Get.put<LanguageProvider>(LanguageProvider());

  List<Locale> get supportedLocales => AppLocalizations.supportedLocales;

  void changeLocale({required String languageCode}) {
    final foundLocale = AppLocalizations.supportedLocales.firstWhereOrNull(
      (element) => element.languageCode == languageCode,
    );
    if (foundLocale == null) {
      throw UnimplementedError();
    }

    locale.value = foundLocale;

    //store this in shared preferences
    _sharedPreferences.setValue(
      key: SharedPreferenceKey.languageCode.value,
      value: languageCode,
    );

    Get.updateLocale(locale.value);
  }

  Future<void> loadFromDefaults() async {
    final storedLanguageCode = await _sharedPreferences.getValue<String>(
      key: SharedPreferenceKey.languageCode.value,
    );

    if (storedLanguageCode != null) {
      changeLocale(languageCode: storedLanguageCode);
    }
  }
}
