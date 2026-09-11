// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get helloWorld => 'Hello World!';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get fare => 'Fare';

  @override
  String get provider => 'Provider';

  @override
  String get runsOn => 'Runs on';

  @override
  String get locationPermissions => 'Location Permissions';

  @override
  String get locationPermissionsDescription =>
      'HambaGo requires location permissions to function properly. Please grant the necessary permissions.';

  @override
  String get howLocationDataIsUsed => 'How location data is used';

  @override
  String get locationDataUsageDescription =>
      'HambaGo uses your location data to provide accurate ride matching and navigation services. Your location data is not shared with third parties without your consent.';

  @override
  String get howLocationDataIsStored => 'How location data is stored';

  @override
  String get locationDataStorageDescription =>
      'HambaGo does not store your location data.';

  @override
  String get allowLocationAccess => 'Allow location access';

  @override
  String get locationAccessDenied => 'Location access denied';

  @override
  String get locationAccessDeniedDescription =>
      'HambaGo requires location access to function properly. Please grant the necessary permissions in your device settings.';

  @override
  String get goToSettings => 'Go to settings';

  @override
  String get accessToLocation => 'Access to location';

  @override
  String get howYouCanUseLocationServices =>
      'How you can use location services';

  @override
  String get howToUseLocationServicesDescription =>
      'Turning on your device location allows you to share your location, which is necessary for HambaGo to provide accurate ride matching and navigation services.';

  @override
  String get howWellUseLocationServices => 'How we\'ll use location services';

  @override
  String get howWellUseLocationServicesDescription =>
      'We\'ll do things like show you where your driver is, and help you find your way to your destination. We won\'t share your location with anyone else without your permission.';

  @override
  String get howYouCanControlThis => 'How you can control this';

  @override
  String get howYouCanControlThisDescription =>
      'You can turn off location services at any time in your device settings. You can also choose to share your location with HambaGo only when you\'re using the app.';

  @override
  String get continueText => 'Continue';

  @override
  String get gettingThingsReady => 'Getting things ready...';

  @override
  String get nearbyTaxis => 'Nearby Taxis';

  @override
  String get spotsAvailable => 'Spots available';

  @override
  String get numberOfSeats => 'Number of seats';

  @override
  String get searchNearbyRoutes => 'Search nearby routes';

  @override
  String get viewRoute => 'View Route';

  @override
  String get searchHere => 'Search here';

  @override
  String get requestARide => 'Request a ride';

  @override
  String get leaveAReview => 'Leave a review';

  @override
  String get moreDetails => 'More details';

  @override
  String get taxiCanBeFoundAt => 'Taxi can be found at';

  @override
  String get routeLength => 'Route length';

  @override
  String get taxiRating => 'Taxi rating';

  @override
  String get myProfile => 'My profile';

  @override
  String get whereDoYouWantToGo => 'Where do you want to go?';

  @override
  String get searchDestination => 'Search for a destination';

  @override
  String get searchAtLeastThreeCharacters =>
      'Enter at least 3 characters to search.';

  @override
  String get noDestinationsFound => 'No destinations found.';

  @override
  String get planningJourney => 'Finding your best available taxi journey...';

  @override
  String get bestAvailableJourney => 'Best available taxi journey';

  @override
  String get walkingEstimateNotice =>
      'Walking links are straight-line estimates because the current data source does not provide pedestrian directions.';

  @override
  String get startJourney => 'Start journey';

  @override
  String get journeyStarted => 'Journey started';

  @override
  String get tryAgain => 'Try again';

  @override
  String get noNearbyRoutes =>
      'No taxi routes were found within 5 km of your current location.';
}
