import 'package:TaxiApp/src/core/routes/permissions_middleware.dart';
import 'package:TaxiApp/src/features/landing/screens/landing_screen.dart';
import 'package:TaxiApp/src/features/my_profile/screens/my_profile_screen.dart';
import 'package:TaxiApp/src/features/my_profile/screens/driver_account_screen.dart';
import 'package:TaxiApp/src/features/permissions_carousel/screens/permissions_carousel_screen.dart';
import 'package:TaxiApp/src/features/search_routes/screens/search_routes_screen.dart';
import 'package:TaxiApp/src/features/ride_requests/screens/ride_requests_screen.dart';
import 'package:get/get.dart';

enum AppRoutes {
  root('/'),
  permissionsCarousel('/permissions-carousel'),
  searchRoutes('/search-routes'),
  myProfile('/my-profile'),
  driverAccount('/driver-account'),
  rideRequests('/ride-requests');

  const AppRoutes(this.value);

  final String value;
}

final initialRoute = AppRoutes.root.value;

final pages = [
  GetPage(
    name: AppRoutes.root.value,
    page: () => const LandingScreen(),
    middlewares: [PermissionsMiddleware(priority: 1)],
  ),
  GetPage(
    name: AppRoutes.permissionsCarousel.value,
    page: () => PermissionsCarouselScreen(),
  ),
  GetPage(
    name: AppRoutes.searchRoutes.value,
    page: () => const SearchRoutesScreen(),
  ),
  GetPage(
    name: AppRoutes.myProfile.value,
    page: () => const MyProfile(),
    middlewares: [],
  ),
  GetPage(
    name: AppRoutes.driverAccount.value,
    page: () => const DriverAccountScreen(),
  ),
  GetPage(name: AppRoutes.rideRequests.value, page: () => RideRequestsScreen()),
];
