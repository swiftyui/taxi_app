import 'package:TaxiApp/src/core/providers/favorite_routes_provider/favorite_routes_provider.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/nearby_taxi_route_model.dart';
import 'package:TaxiApp/src/core/routes/routes.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavoriteRouteButton extends StatelessWidget {
  FavoriteRouteButton({
    required this.route,
    this.size = 30,
    this.showBackground = true,
    super.key,
  });

  final NearbyTaxiRouteModel route;
  final double size;
  final bool showBackground;
  final FavoriteRoutesProvider _provider = FavoriteRoutesProvider.create();

  @override
  Widget build(BuildContext context) => Obx(() {
    final isFavorite = _provider.isFavorite(route.model.id);
    final isUpdating = _provider.updatingRouteIds.contains(route.model.id);
    return Tooltip(
      message: isFavorite
          ? 'Remove from favourite routes'
          : 'Save as favourite route',
      child: SizedBox.square(
        dimension: 40,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isUpdating ? null : () => _toggle(context),
            customBorder: const CircleBorder(),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: showBackground
                      ? (isFavorite
                            ? const Color(0xFFFFF2D0)
                            : const Color(0xFFEAF2F5))
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: isUpdating
                    ? SizedBox.square(
                        dimension: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: isFavorite
                              ? Colours.yellow
                              : Colours.blueThree,
                        ),
                      )
                    : Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite ? Colours.red : Colours.blueThree,
                        size: 17,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  });

  Future<void> _toggle(BuildContext context) async {
    if (!_provider.isSignedIn) {
      Get.snackbar(
        'Save your routes',
        'Sign in to keep favourite routes synced with your account.',
        snackPosition: SnackPosition.BOTTOM,
        mainButton: TextButton(
          onPressed: () {
            Get.closeCurrentSnackbar();
            Get.toNamed<void>(AppRoutes.myProfile.value);
          },
          child: const Text('SIGN IN'),
        ),
      );
      return;
    }

    final succeeded = await _provider.toggle(route);
    if (!succeeded && context.mounted) {
      Get.snackbar(
        'Favourite route',
        _provider.errorMessage.value ?? 'Unable to update this route.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
