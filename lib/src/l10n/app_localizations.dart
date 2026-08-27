import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The conventional newborn programmer greeting
  ///
  /// In en, this message translates to:
  /// **'Hello World!'**
  String get helloWorld;

  /// The conventional from label
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// The conventional to label
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// The conventional fare label
  ///
  /// In en, this message translates to:
  /// **'Fare'**
  String get fare;

  /// The conventional provider label
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// The conventional runs on label
  ///
  /// In en, this message translates to:
  /// **'Runs on'**
  String get runsOn;

  /// The conventional location permissions label
  ///
  /// In en, this message translates to:
  /// **'Location Permissions'**
  String get locationPermissions;

  /// The conventional location permissions description
  ///
  /// In en, this message translates to:
  /// **'HambaGo requires location permissions to function properly. Please grant the necessary permissions.'**
  String get locationPermissionsDescription;

  /// The conventional how location data is used label
  ///
  /// In en, this message translates to:
  /// **'How location data is used'**
  String get howLocationDataIsUsed;

  /// The conventional location data usage description
  ///
  /// In en, this message translates to:
  /// **'HambaGo uses your location data to provide accurate ride matching and navigation services. Your location data is not shared with third parties without your consent.'**
  String get locationDataUsageDescription;

  /// The conventional how location data is stored label
  ///
  /// In en, this message translates to:
  /// **'How location data is stored'**
  String get howLocationDataIsStored;

  /// The conventional location data storage description
  ///
  /// In en, this message translates to:
  /// **'HambaGo does not store your location data.'**
  String get locationDataStorageDescription;

  /// The conventional allow location access button label
  ///
  /// In en, this message translates to:
  /// **'Allow location access'**
  String get allowLocationAccess;

  /// The conventional location access denied label
  ///
  /// In en, this message translates to:
  /// **'Location access denied'**
  String get locationAccessDenied;

  /// The conventional location access denied description
  ///
  /// In en, this message translates to:
  /// **'HambaGo requires location access to function properly. Please grant the necessary permissions in your device settings.'**
  String get locationAccessDeniedDescription;

  /// The conventional go to settings button label
  ///
  /// In en, this message translates to:
  /// **'Go to settings'**
  String get goToSettings;

  /// The conventional access to location label
  ///
  /// In en, this message translates to:
  /// **'Access to location'**
  String get accessToLocation;

  /// The conventional how you can use location services label
  ///
  /// In en, this message translates to:
  /// **'How you can use location services'**
  String get howYouCanUseLocationServices;

  /// The conventional how to use location services description
  ///
  /// In en, this message translates to:
  /// **'Turning on your device location allows you to share your location, which is necessary for HambaGo to provide accurate ride matching and navigation services.'**
  String get howToUseLocationServicesDescription;

  /// The conventional how we'll use location services label
  ///
  /// In en, this message translates to:
  /// **'How we\'ll use location services'**
  String get howWellUseLocationServices;

  /// The conventional how we'll use location services description
  ///
  /// In en, this message translates to:
  /// **'We\'ll do things like show you where your driver is, and help you find your way to your destination. We won\'t share your location with anyone else without your permission.'**
  String get howWellUseLocationServicesDescription;

  /// The conventional how you can control this label
  ///
  /// In en, this message translates to:
  /// **'How you can control this'**
  String get howYouCanControlThis;

  /// The conventional how you can control this description
  ///
  /// In en, this message translates to:
  /// **'You can turn off location services at any time in your device settings. You can also choose to share your location with HambaGo only when you\'re using the app.'**
  String get howYouCanControlThisDescription;

  /// The conventional continue button label
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// The conventional getting things ready label
  ///
  /// In en, this message translates to:
  /// **'Getting things ready...'**
  String get gettingThingsReady;

  /// The conventional nearby taxis label
  ///
  /// In en, this message translates to:
  /// **'Nearby Taxis'**
  String get nearbyTaxis;

  /// The conventional spots available label
  ///
  /// In en, this message translates to:
  /// **'Spots available'**
  String get spotsAvailable;

  /// The conventional number of seats label
  ///
  /// In en, this message translates to:
  /// **'Number of seats'**
  String get numberOfSeats;

  /// The conventional search nearby routes label
  ///
  /// In en, this message translates to:
  /// **'Search nearby routes'**
  String get searchNearbyRoutes;

  /// The conventional view route button label
  ///
  /// In en, this message translates to:
  /// **'View Route'**
  String get viewRoute;

  /// The conventional search here button label
  ///
  /// In en, this message translates to:
  /// **'Search here'**
  String get searchHere;

  /// The conventional request a ride button label
  ///
  /// In en, this message translates to:
  /// **'Request a ride'**
  String get requestARide;

  /// The conventional leave a review button label
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get leaveAReview;

  /// The conventional more details button label
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get moreDetails;

  /// The conventional taxi can be found at label
  ///
  /// In en, this message translates to:
  /// **'Taxi can be found at'**
  String get taxiCanBeFoundAt;

  /// The conventional route length label
  ///
  /// In en, this message translates to:
  /// **'Route length'**
  String get routeLength;

  /// The conventional taxi rating label
  ///
  /// In en, this message translates to:
  /// **'Taxi rating'**
  String get taxiRating;

  /// The conventional my profile label
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
