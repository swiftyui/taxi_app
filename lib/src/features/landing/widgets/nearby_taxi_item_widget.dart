import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/nearby_taxi_route_model.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/features/landing/enums/day_of_week.dart';
import 'package:TaxiApp/src/features/landing/widgets/nearby_taxi_week_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NearbyTaxiItemWidget extends StatelessWidget {
  const NearbyTaxiItemWidget({required this.route, super.key});

  final NearbyTaxiRouteModel route;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(Dimensions.eight),
      border: Border.all(color: Colours.charcoal, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.6),
          blurRadius: 2,
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
              value: 'R${route.model.properties.fare.toStringAsFixed(2)}',
            ).paddingOnly(bottom: Dimensions.eight),
            _buildValueItem(
              label: Get.appLocalizations.provider,
              value: route.model.properties.assocname,
            ).paddingOnly(bottom: Dimensions.eight),
            NearbyTaxiWeekPill(
              dayOfWeek: DayOfWeek.fromValue(route.model.properties.dayofweek),
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
