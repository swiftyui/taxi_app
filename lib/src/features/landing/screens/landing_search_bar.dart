import 'package:TaxiApp/src/core/enums/image_list.dart';
import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/extensions/typed_extensions.dart';
import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/nearby_taxi_route_model.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:TaxiApp/src/core/routes/routes.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class LandingSearchBar extends StatefulWidget {
  const LandingSearchBar({super.key});

  @override
  State<LandingSearchBar> createState() => _LandingSearchBarState();
}

class _LandingSearchBarState extends State<LandingSearchBar> {
  static const double _searchBarHeight = 50.0;

  final ActionsProvider _actionsProvider = ActionsProvider.create();

  @override
  Widget build(BuildContext context) =>
      Container(
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
        child: Obx(
          () => Row(
            children: [
              SvgPicture.asset(
                ImageList.taxiIcon,
                width: 36,
                height: 36,
              ).paddingOnly(right: Dimensions.eight),
              Expanded(
                child: Text(
                  _actionsProvider.selectedRoute.value?.destinationName ??
                      Get.appLocalizations.searchNearbyRoutes,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ).paddingOnly(left: Dimensions.eight, right: Dimensions.eight),
        ),
      ).onTap(() async {
        final result = await Get.toNamed(AppRoutes.searchRoutes.value);
        if (result != null && result is TaxiRouteModel) {
          _actionsProvider.setSelectedRoute(
            NearbyTaxiRouteModel.fromTaxiRouteModel(result),
          );
          _actionsProvider.viewRoute(
            NearbyTaxiRouteModel.fromTaxiRouteModel(result),
          );
        }
      });
}
