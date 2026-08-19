import 'package:TaxiApp/src/core/routes/routes.dart';
import 'package:TaxiApp/src/features/permissions_carousel/providers/permissions_carousel_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class PermissionsMiddleware extends GetMiddleware {
  PermissionsMiddleware({super.priority});

  @override
  RouteSettings? redirect(String? route) {
    if (route == null) {
      return null;
    }

    final PermissionsCarouselProvider permissionsCarouselProvider =
        PermissionsCarouselProvider.create();

    /// If the user has already granted all permissions, allow them to proceed to the requested route.
    if (permissionsCarouselProvider.allPermissionsGranted.value) {
      return null;
    }

    return RouteSettings(name: AppRoutes.permissionsCarousel.value);
  }
}
