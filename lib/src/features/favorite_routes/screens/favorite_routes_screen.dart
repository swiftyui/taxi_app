import 'package:TaxiApp/src/core/models/favorite_route.dart';
import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/providers/favorite_routes_provider/favorite_routes_provider.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/nearby_taxi_route_model.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/taxi_routes_provider.dart';
import 'package:TaxiApp/src/core/routes/routes.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/widgets/app_bars/custom_app_bar.dart';
import 'package:TaxiApp/src/core/widgets/loaders/hambago_shimmer.dart';
import 'package:TaxiApp/src/features/favorite_routes/widgets/favorite_route_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavoriteRoutesScreen extends StatelessWidget {
  FavoriteRoutesScreen({super.key});

  final FavoriteRoutesProvider _provider = FavoriteRoutesProvider.create();
  final TaxiRoutesProvider _taxiRoutesProvider = TaxiRoutesProvider.create();
  final ActionsProvider _actionsProvider = ActionsProvider.create();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colours.lightSurface,
    appBar: const HambaGoAppBar(
      title: 'Favourite routes',
      subtitle: 'Your quickest way back to regular trips',
    ),
    body: Obx(() {
      if (!_provider.isSignedIn) {
        return _EmptyFavorites(
          icon: Icons.favorite_border_rounded,
          title: 'Sign in to save routes',
          message:
              'Your favourite taxi routes will stay synced across devices.',
          actionLabel: 'Go to profile',
          onAction: () => Get.toNamed<void>(AppRoutes.myProfile.value),
        );
      }
      if (_provider.isLoading.value) {
        return const TaxiRoutesShimmer(itemCount: 3);
      }
      if (_provider.favorites.isEmpty) {
        return const _EmptyFavorites(
          icon: Icons.route_outlined,
          title: 'No favourite routes yet',
          message:
              'Tap the heart on a taxi route to keep it close for your next trip.',
        );
      }

      _taxiRoutesProvider.taxiRoutes.length;
      return RefreshIndicator(
        color: Colours.blueThree,
        onRefresh: _taxiRoutesProvider.loadRoutes,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          itemCount: _provider.favorites.length,
          itemBuilder: (context, index) {
            final favorite = _provider.favorites[index];
            final route = _provider.resolveRoute(favorite);
            return _FavoriteRouteCard(
              favorite: favorite,
              route: route,
              onOpen: route == null ? null : () => _openRoute(route),
              onRemove: () => _provider.remove(favorite),
            ).paddingOnly(bottom: Dimensions.eight);
          },
        ),
      );
    }),
  );

  void _openRoute(NearbyTaxiRouteModel route) {
    _actionsProvider.viewRoute(route);
    Get.offAllNamed<void>(AppRoutes.root.value);
  }
}

class _FavoriteRouteCard extends StatelessWidget {
  const _FavoriteRouteCard({
    required this.favorite,
    required this.route,
    required this.onOpen,
    required this.onRemove,
  });

  final FavoriteRoute favorite;
  final NearbyTaxiRouteModel? route;
  final VoidCallback? onOpen;
  final Future<bool> Function() onRemove;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 1,
    shadowColor: Colours.primaryOne.withValues(alpha: 0.14),
    borderRadius: BorderRadius.circular(14),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.twelve),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F1F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_taxi_rounded,
                color: Colours.blueThree,
                size: 21,
              ),
            ),
            const SizedBox(width: Dimensions.twelve),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RouteStop(label: 'FROM', value: favorite.originName),
                  Container(
                    width: 1,
                    height: 10,
                    margin: const EdgeInsets.only(left: 3),
                    color: Colours.blueTwo,
                  ),
                  _RouteStop(label: 'TO', value: favorite.destinationName),
                  const SizedBox(height: Dimensions.eight),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _RoutePill(
                        icon: Icons.payments_outlined,
                        label: 'R${favorite.fare.toStringAsFixed(2)}',
                      ),
                      if (favorite.associationName.isNotEmpty)
                        _RoutePill(
                          icon: Icons.groups_2_outlined,
                          label: favorite.associationName,
                        ),
                    ],
                  ),
                  if (route == null)
                    const Text(
                      'Route details are currently unavailable. Pull to retry.',
                      style: TextStyle(
                        color: Colours.charcoalLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ).paddingOnly(top: Dimensions.eight),
                ],
              ),
            ),
            if (route != null)
              FavoriteRouteButton(route: route!, showBackground: false)
            else
              Obx(
                () => IconButton(
                  onPressed:
                      FavoriteRoutesProvider.create().updatingRouteIds.contains(
                        favorite.featureId,
                      )
                      ? null
                      : onRemove,
                  tooltip: 'Remove from favourite routes',
                  icon: const Icon(
                    Icons.favorite_rounded,
                    color: Colours.red,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 7,
        height: 7,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: label == 'FROM' ? Colours.yellow : Colours.blueThree,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colours.charcoalLight,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colours.primaryOne,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _RoutePill extends StatelessWidget {
  const _RoutePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 210),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F5F7),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colours.blueThree, size: 13),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colours.primaryOne,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: Color(0xFFE6F1F5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colours.blueThree, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colours.primaryOne,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colours.charcoalLight,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (onAction != null)
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.person_outline_rounded),
              label: Text(actionLabel!),
              style: FilledButton.styleFrom(backgroundColor: Colours.blueThree),
            ).paddingOnly(top: Dimensions.sixteen),
        ],
      ),
    ),
  );
}
