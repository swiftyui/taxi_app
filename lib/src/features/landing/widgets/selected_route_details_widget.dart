import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/extensions/typed_extensions.dart';
import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/widgets/expandables/expandable_item.dart';
import 'package:TaxiApp/src/core/widgets/ratings/taxi_ratings.dart';
import 'package:TaxiApp/src/features/landing/enums/day_of_week.dart';
import 'package:TaxiApp/src/features/landing/widgets/nearby_taxi_spots_available.dart';
import 'package:TaxiApp/src/features/landing/widgets/nearby_taxi_week_pill.dart';
import 'package:TaxiApp/src/features/landing/widgets/taxi_actions.dart';
import 'package:flutter/material.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
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
            borderRadius: BorderRadius.circular(Dimensions.eight),
            boxShadow: [
              BoxShadow(
                color: Colours.primaryOne.withValues(alpha: .2),
                blurRadius: Dimensions.four,
                offset: const Offset(0, 2),
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => _actionsProvider.clearSelectedRoute(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colours.charcoal.lighten(0.75),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 22,
                        ).paddingAll(Dimensions.four),
                      ),
                    ),
                  ),
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
                  ),
                  NearbyTaxiSpotsAvailable(
                    route: _actionsProvider.selectedRoute.value!,
                  ).paddingOnly(top: Dimensions.eight),
                  TaxiRatings().paddingOnly(top: Dimensions.eight),
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
                  _viewRouteButton.paddingOnly(top: Dimensions.eight),
                ],
              ),
            ],
          ).paddingAll(Dimensions.eight),
        ).paddingOnly(
          left: Dimensions.eight,
          right: Dimensions.eight,
          bottom: Dimensions.eight,
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
