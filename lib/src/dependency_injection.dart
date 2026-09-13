import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/providers/maps_provider/maps_provider.dart';
import 'package:TaxiApp/src/core/providers/my_profile_provider/my_profile_provider.dart';
import 'package:TaxiApp/src/core/providers/route_reviews_provider/route_reviews_provider.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/taxi_routes_provider.dart';
import 'package:TaxiApp/src/core/providers/travel_log_provider/travel_log_provider.dart';
import 'package:TaxiApp/src/core/providers/user_location_provider/user_location_provider.dart';

Future<void> dependencyInjection() async {
  MapsProvider.create();
  UserLocationProvider.create();
  TaxiRoutesProvider.create();
  TravelLogProvider.create();
  RouteReviewsProvider.create();
  ActionsProvider.create();
  MyProfileProvider.create();
}
