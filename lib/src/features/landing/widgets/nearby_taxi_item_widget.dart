import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/nearby_taxi_route_model.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/features/landing/enums/day_of_week.dart';
import 'package:TaxiApp/src/features/landing/widgets/nearby_taxi_spots_available.dart';
import 'package:TaxiApp/src/features/landing/widgets/nearby_taxi_week_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NearbyTaxiItemWidget extends StatelessWidget {
  const NearbyTaxiItemWidget({required this.route, super.key});

  final NearbyTaxiRouteModel route;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      color: Colours.primaryOne,
      borderRadius: BorderRadius.circular(Dimensions.eight),
    ),
    child: Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colours.primaryTwo,
        borderRadius: BorderRadius.circular(Dimensions.eight),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colours.primaryThree,
          borderRadius: BorderRadius.circular(Dimensions.eight),
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colours.primaryFour,
            borderRadius: BorderRadius.circular(Dimensions.eight),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colours.charcoal,
              borderRadius: BorderRadius.circular(Dimensions.eight),
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
                  ],
                ),
              ],
            ).paddingAll(Dimensions.eight),
          ),
        ),
      ),
    ),
  );

  Widget _buildValueItem({required String label, required String value}) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Get.textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
          Text(
            value,
            style: Get.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      );
}
