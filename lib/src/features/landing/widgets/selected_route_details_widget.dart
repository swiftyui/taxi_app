import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/widgets/buttons/primary_button.dart';
import 'package:TaxiApp/src/core/widgets/expandables/expandable_item.dart';
import 'package:TaxiApp/src/core/widgets/ratings/taxi_ratings.dart';
import 'package:TaxiApp/src/features/favorite_routes/widgets/favorite_route_button.dart';
import 'package:TaxiApp/src/features/landing/enums/day_of_week.dart';
import 'package:TaxiApp/src/features/landing/widgets/nearby_taxi_spots_available.dart';
import 'package:TaxiApp/src/features/landing/widgets/nearby_taxi_week_pill.dart';
import 'package:TaxiApp/src/features/landing/widgets/ride_request_action.dart';
import 'package:TaxiApp/src/features/landing/widgets/taxi_actions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelectedRouteDetailsWidget extends StatefulWidget {
  const SelectedRouteDetailsWidget({super.key});

  @override
  State<SelectedRouteDetailsWidget> createState() =>
      _SelectedRouteDetailsWidgetState();
}

class _SelectedRouteDetailsWidgetState
    extends State<SelectedRouteDetailsWidget> {
  final ActionsProvider _actionsProvider = ActionsProvider.create();
  @override
  Widget build(BuildContext context) => Obx(
    () =>
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDCE7EA)),
            boxShadow: [
              BoxShadow(
                color: Colours.primaryOne.withValues(alpha: .1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Route details',
                              style: TextStyle(
                                color: Colours.primaryOne,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Taxi route information',
                              style: TextStyle(
                                color: Colours.charcoalLight,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FavoriteRouteButton(
                        route: _actionsProvider.selectedRoute.value!,
                        size: 28,
                      ),
                      _RouteHeaderAction(
                        tooltip: 'Close route details',
                        icon: Icons.close_rounded,
                        onTap: _actionsProvider.clearSelectedRoute,
                      ),
                    ],
                  ).paddingOnly(bottom: Dimensions.twelve),
                  _buildValueItem(
                    label: Get.appLocalizations.from,
                    value:
                        _actionsProvider
                            .selectedRoute
                            .value
                            ?.model
                            .properties
                            .originname ??
                        '',
                  ).paddingOnly(bottom: Dimensions.eight),
                  _buildValueItem(
                    label: Get.appLocalizations.to,
                    value:
                        _actionsProvider
                            .selectedRoute
                            .value
                            ?.model
                            .properties
                            .destname ??
                        '',
                  ).paddingOnly(bottom: Dimensions.eight),
                  _buildValueItem(
                    label: Get.appLocalizations.fare,
                    value:
                        'R${_actionsProvider.selectedRoute.value?.model.properties.fare.toStringAsFixed(2) ?? '0.00'}',
                  ).paddingOnly(bottom: Dimensions.eight),
                  _buildValueItem(
                    label: Get.appLocalizations.provider,
                    value:
                        _actionsProvider
                            .selectedRoute
                            .value
                            ?.model
                            .properties
                            .assocname ??
                        '',
                  ).paddingOnly(bottom: Dimensions.eight),
                  NearbyTaxiWeekPill(
                    dayOfWeek: DayOfWeek.fromValue(
                      _actionsProvider
                          .selectedRoute
                          .value!
                          .model
                          .properties
                          .dayofweek,
                    ),
                    serviceDays:
                        _actionsProvider.selectedRoute.value!.model.serviceDays,
                    departureTime: _actionsProvider
                        .selectedRoute
                        .value!
                        .model
                        .departureTime,
                  ),
                  NearbyTaxiSpotsAvailable(
                    route: _actionsProvider.selectedRoute.value!,
                  ).paddingOnly(top: Dimensions.eight),
                  TaxiRatings(
                    route: _actionsProvider.selectedRoute.value!.model,
                  ).paddingOnly(top: Dimensions.eight),
                  ExpandableItem(
                    title: Get.appLocalizations.moreDetails,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildValueItem(
                          label: Get.appLocalizations.taxiCanBeFoundAt,
                          value: _actionsProvider
                              .selectedRoute
                              .value!
                              .model
                              .properties
                              .originpnt,
                        ).paddingOnly(bottom: Dimensions.eight),
                        _buildValueItem(
                          label: Get.appLocalizations.routeLength,
                          value:
                              '${_actionsProvider.selectedRoute.value!.model.properties.routelengt} km',
                        ),
                      ],
                    ),
                  ).paddingOnly(
                    top: Dimensions.eight,
                    bottom: Dimensions.eight,
                  ),
                  RideRequestAction(
                    route: _actionsProvider.selectedRoute.value!,
                  ).paddingOnly(bottom: Dimensions.eight),
                  _startJourneyButton.paddingOnly(top: Dimensions.eight),
                  _viewRouteButton.paddingOnly(top: Dimensions.twelve),
                ],
              ),
            ],
          ).paddingAll(Dimensions.twelve),
        ).paddingOnly(
          left: Dimensions.eight,
          right: Dimensions.eight,
          bottom: Dimensions.eight,
        ),
  );

  Widget get _startJourneyButton => PrimaryButton(
    text: Get.appLocalizations.startJourney,
    buttonColor: Colours.primaryOne,
    borderColor: Colours.primaryOne,
    buttonHeight: 48,
    buttonWidth: double.infinity,
    borderRadius: BorderRadius.circular(14),
    icon: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
    onTap: () => _actionsProvider.startJourneyOnRoute(
      _actionsProvider.selectedRoute.value!,
    ),
  );

  Widget get _viewRouteButton => TaxiAction(
    icon: Icons.directions,
    label: Get.appLocalizations.viewRoute,
    onTap: () =>
        _actionsProvider.viewRoute(_actionsProvider.selectedRoute.value!),
  );

  Widget _buildValueItem({required String label, required String value}) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Get.textTheme.labelMedium?.copyWith(color: Colors.black),
          ),
          Text(
            value,
            style: Get.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      );
}

class _RouteHeaderAction extends StatelessWidget {
  const _RouteHeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: SizedBox.square(
      dimension: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFE9EBEE),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colours.primaryOne, size: 17),
            ),
          ),
        ),
      ),
    ),
  );
}
