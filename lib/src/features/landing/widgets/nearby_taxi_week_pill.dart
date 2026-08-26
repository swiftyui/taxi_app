import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/features/landing/enums/day_of_week.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NearbyTaxiWeekPill extends StatelessWidget {
  const NearbyTaxiWeekPill({required this.dayOfWeek, super.key});

  final DayOfWeek dayOfWeek;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        Get.appLocalizations.runsOn,
        style: Get.textTheme.labelMedium?.copyWith(color: Colors.black),
      ).paddingOnly(bottom: Dimensions.four),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: DayOfWeek.values.map((day) {
            final isSelected = day == dayOfWeek;
            return Container(
              decoration: BoxDecoration(
                color: isSelected ? Colours.blueThree : Colors.grey[300],
                borderRadius: BorderRadius.circular(Dimensions.four),
              ),
              child:
                  Text(
                    day.value,
                    style: Get.textTheme.labelLarge?.copyWith(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ).paddingOnly(
                    left: Dimensions.eight,
                    right: Dimensions.eight,
                    top: Dimensions.four,
                    bottom: Dimensions.four,
                  ),
            ).paddingOnly(right: Dimensions.four);
          }).toList(),
        ),
      ),
    ],
  );
}
