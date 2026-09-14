import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/providers/driver_account_provider/driver_account_provider.dart';
import 'package:TaxiApp/src/core/providers/driver_reviews_provider/driver_reviews_provider.dart';
import 'package:TaxiApp/src/core/providers/favorite_routes_provider/favorite_routes_provider.dart';
import 'package:TaxiApp/src/core/providers/hamba_points_provider/hamba_points_provider.dart';
import 'package:TaxiApp/src/core/providers/maps_provider/maps_provider.dart';
import 'package:TaxiApp/src/core/providers/my_profile_provider/my_profile_provider.dart';
import 'package:TaxiApp/src/core/providers/route_reviews_provider/route_reviews_provider.dart';
import 'package:TaxiApp/src/core/providers/ride_requests_provider/ride_requests_provider.dart';
import 'package:TaxiApp/src/core/providers/safety_provider/safety_provider.dart';
import 'package:TaxiApp/src/core/providers/saved_places_provider/saved_places_provider.dart';
import 'package:TaxiApp/src/core/providers/route_occupancy_provider/route_occupancy_provider.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/taxi_routes_provider.dart';
import 'package:TaxiApp/src/core/providers/travel_log_provider/travel_log_provider.dart';
import 'package:TaxiApp/src/core/providers/user_location_provider/user_location_provider.dart';

Future<void> dependencyInjection() async {
  MapsProvider.create();
  UserLocationProvider.create();
  TaxiRoutesProvider.create();
  FavoriteRoutesProvider.create();
  SavedPlacesProvider.create();
  DriverAccountProvider.create();
  DriverReviewsProvider.create();
  HambaPointsProvider.create();
  TravelLogProvider.create();
  RouteReviewsProvider.create();
  RideRequestsProvider.create();
  RouteOccupancyProvider.create();
  ActionsProvider.create();
  SafetyProvider.create();
  MyProfileProvider.create();
}
