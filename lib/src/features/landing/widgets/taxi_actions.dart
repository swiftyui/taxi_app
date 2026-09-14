import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
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
          Expanded(
            child: TaxiAction(
              label: Get.appLocalizations.requestARide,
              icon: Icons.local_taxi_rounded,
            ),
          ),
        ],
      ).paddingOnly(
        left: Dimensions.eight,
        right: Dimensions.eight,
        top: Dimensions.eight,
        bottom: Dimensions.eight,
      );
}

class TaxiAction extends StatelessWidget {
  const TaxiAction({
    required this.label,
    required this.icon,
    this.onTap,
    super.key,
  });
  final String label;
  final IconData icon;
  static const double _actionHeight = 40;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(
                  color: Colours.primaryOne.withValues(alpha: .2),
                  blurRadius: Dimensions.four,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox(
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
              ).paddingOnly(right: Dimensions.sixteen),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colours.primaryOne,
                size: Dimensions.sixteen,
              ).paddingOnly(right: Dimensions.eight),
              Expanded(
                child: Text(
                  label,
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
      ),
    ),
  );
}
