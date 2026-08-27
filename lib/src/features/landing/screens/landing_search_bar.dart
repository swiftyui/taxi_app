import 'package:TaxiApp/src/core/enums/image_list.dart';
import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/extensions/typed_extensions.dart';
import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/nearby_taxi_route_model.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:TaxiApp/src/core/routes/routes.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/features/my_profile/widgets/profile_image.dart';
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
  Widget build(BuildContext context) => Container(
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            ImageList.locationIcon,
            width: 36,
            height: 36,
          ).paddingOnly(right: Dimensions.eight),
          Expanded(
            child: _textToDisplay.onTap(() async {
              final result = await Get.toNamed(AppRoutes.searchRoutes.value);
              if (result != null && result is TaxiRouteModel) {
                _actionsProvider.setSelectedRoute(
                  NearbyTaxiRouteModel.fromTaxiRouteModel(result),
                );
                _actionsProvider.viewRoute(
                  NearbyTaxiRouteModel.fromTaxiRouteModel(result),
                );
              }
            }),
          ),
          const ProfileImage()
              .onTap(() async {
                await Get.toNamed(AppRoutes.myProfile.value);
              })
              .paddingOnly(
                top: Dimensions.four,
                bottom: Dimensions.four,
                left: Dimensions.eight,
                right: Dimensions.eight,
              ),
        ],
      ).paddingOnly(left: Dimensions.eight),
    ),
  );

  Widget get _textToDisplay {
    if (_actionsProvider.selectedRoute.value == null) {
      return Text(
        Get.appLocalizations.searchNearbyRoutes,
        style: Get.textTheme.bodyMedium?.copyWith(color: Colors.black),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _actionsProvider.selectedRoute.value?.originName ??
                Get.appLocalizations.searchNearbyRoutes,
            style: Get.textTheme.labelLarge?.copyWith(color: Colors.black),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _actionsProvider.selectedRoute.value?.destinationName ??
                Get.appLocalizations.searchNearbyRoutes,
            style: Get.textTheme.bodyMedium?.copyWith(color: Colors.black),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
  }
}
