import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TaxiActions extends StatelessWidget {
  const TaxiActions({super.key});

  @override
  Widget build(BuildContext context) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(child: TaxiAction()),
          const SizedBox(width: Dimensions.four),
          Expanded(child: TaxiAction()),
        ],
      ).paddingOnly(
        left: Dimensions.eight,
        right: Dimensions.eight,
        top: Dimensions.eight,
        bottom: Dimensions.eight,
      );
}

class TaxiAction extends StatelessWidget {
  const TaxiAction({super.key});

  static const double _actionHeight = 40;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Dimensions.four),
          boxShadow: [
            BoxShadow(
              color: Colours.primaryOne.withValues(alpha: .2),
              blurRadius: Dimensions.four,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          height: _actionHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 3,
                height: _actionHeight,
                decoration: const BoxDecoration(color: Colours.red),
              ),
              Container(
                width: 3,
                height: _actionHeight,
                decoration: const BoxDecoration(color: Colours.green),
              ),
              Container(
                width: 3,
                height: _actionHeight,
                decoration: const BoxDecoration(color: Colours.yellow),
              ),
              Container(
                width: 3,
                height: _actionHeight,
                decoration: const BoxDecoration(color: Colours.blue),
              ),
            ],
          ),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_taxi_rounded,
            color: Colours.primaryOne,
            size: Dimensions.sixteen,
          ).paddingOnly(right: Dimensions.eight),
          Expanded(
            child: Text(
              'Request a ride',
              style: Get.textTheme.labelLarge?.copyWith(
                color: Colours.primaryOne,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ).paddingOnly(
        top: Dimensions.eight,
        bottom: Dimensions.eight,
        left: Dimensions.sixteen,
        right: Dimensions.sixteen,
      ),
    ],
  );
}
