import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/extensions/typed_extensions.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/nearby_taxi_route_model.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/widgets/expandables/expandable_item.dart';
import 'package:TaxiApp/src/core/widgets/ratings/taxi_ratings.dart';
import 'package:TaxiApp/src/features/landing/enums/day_of_week.dart';
import 'package:TaxiApp/src/features/landing/widgets/nearby_taxi_spots_available.dart';
import 'package:TaxiApp/src/features/landing/widgets/nearby_taxi_week_pill.dart';
import 'package:TaxiApp/src/features/landing/widgets/taxi_actions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NearbyTaxiItemWidget extends StatelessWidget {
  const NearbyTaxiItemWidget({
    required this.route,
    required this.onTap,
    super.key,
  });

  final NearbyTaxiRouteModel route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
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
                    _buildValueItem(
                      label: Get.appLocalizations.from,
                      value: route.originName,
                    ).paddingOnly(bottom: Dimensions.eight),
                    _buildValueItem(
                      label: Get.appLocalizations.to,
                      value: route.destinationName,
                    ).paddingOnly(bottom: Dimensions.eight),
                    _buildValueItem(
                      label: Get.appLocalizations.fare,
                      value:
                          'R${route.model.properties.fare.toStringAsFixed(2)}',
                    ).paddingOnly(bottom: Dimensions.eight),
                    _buildValueItem(
                      label: Get.appLocalizations.provider,
                      value: route.model.properties.assocname,
                    ).paddingOnly(bottom: Dimensions.eight),
                    NearbyTaxiWeekPill(
                      dayOfWeek: DayOfWeek.fromValue(
                        route.model.properties.dayofweek,
                      ),
                    ),
                    NearbyTaxiSpotsAvailable(
                      route: route,
                    ).paddingOnly(top: Dimensions.eight),
                    TaxiRatings(
                      route: route.model,
                    ).paddingOnly(top: Dimensions.eight),
                    ExpandableItem(
                      title: Get.appLocalizations.moreDetails,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildValueItem(
                            label: Get.appLocalizations.taxiCanBeFoundAt,
                            value: route.model.properties.originpnt,
                          ).paddingOnly(bottom: Dimensions.eight),
                          _buildValueItem(
                            label: Get.appLocalizations.routeLength,
                            value: '${route.model.properties.routelengt} km',
                          ),
                        ],
                      ),
                    ).paddingOnly(
                      top: Dimensions.eight,
                      bottom: Dimensions.eight,
                    ),
                    TaxiAction(
                      label: Get.appLocalizations.requestARide,
                      icon: Icons.local_taxi_rounded,
                    ).paddingOnly(bottom: Dimensions.eight),
                  ],
                ),
              ],
            ).paddingAll(Dimensions.eight),
          )
          .paddingOnly(
            left: Dimensions.eight,
            right: Dimensions.eight,
            bottom: Dimensions.eight,
          )
          .onTap(onTap);

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
