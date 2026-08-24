import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LandingSearchBar extends StatefulWidget {
  const LandingSearchBar({super.key});

  @override
  State<LandingSearchBar> createState() => _LandingSearchBarState();
}

class _LandingSearchBarState extends State<LandingSearchBar> {
  static const double _searchBarHeight = 50.0;

  @override
  Widget build(BuildContext context) =>
      SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: double.infinity,
            height: _searchBarHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.black,
                ).paddingOnly(right: Dimensions.eight),
                Expanded(
                  child: Text(
                    Get.appLocalizations.searchNearbyRoutes,
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ).paddingOnly(left: Dimensions.eight, right: Dimensions.eight),
          ),
        ),
      ).paddingOnly(
        left: Dimensions.sixteen,
        right: Dimensions.sixteen,
        top: Dimensions.sixteen,
      );
}
