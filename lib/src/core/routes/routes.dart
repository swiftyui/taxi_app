import 'package:TaxiApp/src/core/routes/permissions_middleware.dart';
import 'package:TaxiApp/src/features/landing/screens/landing_screen.dart';
import 'package:TaxiApp/src/features/permissions_carousel/screens/permissions_carousel_screen.dart';
import 'package:get/get.dart';

enum AppRoutes {
  root('/'),
  permissionsCarousel('/permissions-carousel');

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
];
