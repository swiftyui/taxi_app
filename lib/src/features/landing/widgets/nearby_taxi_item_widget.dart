import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/features/landing/enums/day_of_week.dart';
import 'package:TaxiApp/src/features/landing/widgets/nearby_taxi_week_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NearbyTaxiItemWidget extends StatelessWidget {
  const NearbyTaxiItemWidget({required this.route, super.key});

  final TaxiRouteModel route;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(Dimensions.eight),
      border: Border.all(color: Colours.charcoal, width: 1),
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
              value: route.properties.originname,
            ).paddingOnly(bottom: Dimensions.eight),
            _buildValueItem(
              label: Get.appLocalizations.to,
              value: route.properties.destname,
            ).paddingOnly(bottom: Dimensions.eight),
            _buildValueItem(
              label: Get.appLocalizations.fare,
              value: 'R${route.properties.fare.toStringAsFixed(2)}',
            ).paddingOnly(bottom: Dimensions.eight),
            _buildValueItem(
              label: Get.appLocalizations.provider,
              value: route.properties.assocname,
            ).paddingOnly(bottom: Dimensions.eight),
            NearbyTaxiWeekPill(
              dayOfWeek: DayOfWeek.fromValue(route.properties.dayofweek),
            ),
          ],
        ),
      ],
    ).paddingAll(Dimensions.eight),
  );

  Widget _buildValueItem({required String label, required String value}) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Get.textTheme.labelMedium),
          Text(
            value,
            style: Get.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
}
