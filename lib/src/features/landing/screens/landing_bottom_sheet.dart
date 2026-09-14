import 'package:TaxiApp/src/core/enums/action_type.dart';
import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/providers/favorite_routes_provider/favorite_routes_provider.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/taxi_routes_provider.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/routes/routes.dart';
import 'package:TaxiApp/src/core/widgets/loaders/hambago_shimmer.dart';
import 'package:TaxiApp/src/features/landing/widgets/nearby_taxi_item_widget.dart';
import 'package:TaxiApp/src/features/landing/widgets/journey_details_widget.dart';
import 'package:TaxiApp/src/features/landing/widgets/selected_route_details_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LandingBottomSheet extends StatelessWidget {
  LandingBottomSheet({super.key});

  final TaxiRoutesProvider _taxiRoutesProvider = TaxiRoutesProvider.create();
  final ActionsProvider _actionsProvider = ActionsProvider.create();
  final FavoriteRoutesProvider _favoriteRoutesProvider =
      FavoriteRoutesProvider.create();

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.15,
    minChildSize: 0.15,
    maxChildSize: 0.85,
    snap: true,
    snapSizes: const [0.15, 0.45, 0.85],
    builder: (context, scrollController) => Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Dimensions.sixteen),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Obx(
        () => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: _dragHandle,
              ).paddingOnly(top: Dimensions.sixteen, bottom: Dimensions.eight),
              _buildBottomSheetContent,
            ],
          ),
        ),
      ),
    ),
  );

  Widget get _dragHandle => Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: Colours.charcoalLight,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget get _buildBottomSheetContent {
    switch (_actionsProvider.selectedAction.value) {
      case ActionType.selectedLocation:
      case ActionType.viewRoute:
        return const SelectedRouteDetailsWidget();
      case ActionType.planningJourney:
      case ActionType.journeyReady:
      case ActionType.journeyStarted:
      case ActionType.journeyCompleted:
        return JourneyDetailsWidget();
      default:
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    Get.appLocalizations.nearbyTaxis,
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Obx(() {
                  final favoriteCount =
                      _favoriteRoutesProvider.favorites.length;
                  return Material(
                    color: const Color(0xFFFFF2D0),
                    borderRadius: BorderRadius.circular(99),
                    child: InkWell(
                      onTap: () =>
                          Get.toNamed<void>(AppRoutes.favoriteRoutes.value),
                      borderRadius: BorderRadius.circular(99),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              color: Colours.red,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _favoriteRoutesProvider.isSignedIn
                                  ? 'Saved $favoriteCount'
                                  : 'Saved',
                              style: const TextStyle(
                                color: Colours.primaryOne,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ).paddingOnly(
              bottom: Dimensions.eight,
              left: Dimensions.eight,
              right: Dimensions.eight,
            ),

            _taxiRoutesProvider.isLoading.value
                ? const TaxiRoutesShimmer()
                : _taxiRoutesProvider.errorMessage.value != null &&
                      _taxiRoutesProvider.nearbyRoutes.isEmpty
                ? _RouteStatus(
                    message: _taxiRoutesProvider.errorMessage.value!,
                    actionLabel: Get.appLocalizations.tryAgain,
                    onAction: _taxiRoutesProvider.loadRoutes,
                  )
                : _taxiRoutesProvider.nearbyRoutes.isEmpty
                ? _RouteStatus(message: Get.appLocalizations.noNearbyRoutes)
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _taxiRoutesProvider.nearbyRoutes.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) => NearbyTaxiItemWidget(
                      route: _taxiRoutesProvider.nearbyRoutes[index],
                      onTap: () {
                        _actionsProvider.setSelectedRoute(
                          _taxiRoutesProvider.nearbyRoutes[index],
                        );
                        _actionsProvider.viewRoute(
                          _taxiRoutesProvider.nearbyRoutes[index],
                        );
                      },
                    ),
                  ),
          ],
        );
    }
  }
}

class _RouteStatus extends StatelessWidget {
  const _RouteStatus({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: Get.textTheme.bodyMedium?.copyWith(
            color: Colours.charcoalLight,
          ),
        ),
        if (onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    ).paddingAll(Dimensions.sixteen),
  );
}
