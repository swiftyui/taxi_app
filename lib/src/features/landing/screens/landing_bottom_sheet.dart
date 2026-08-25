import 'package:TaxiApp/src/core/enums/action_type.dart';
import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/taxi_routes_provider.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/widgets/loaders/generic_loader.dart';
import 'package:TaxiApp/src/features/landing/widgets/nearby_taxi_item_widget.dart';
import 'package:TaxiApp/src/features/landing/widgets/selected_route_details_widget.dart';
import 'package:TaxiApp/src/features/landing/widgets/taxi_actions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LandingBottomSheet extends StatelessWidget {
  LandingBottomSheet({super.key});

  final TaxiRoutesProvider _taxiRoutesProvider = TaxiRoutesProvider.create();
  final ActionsProvider _actionsProvider = ActionsProvider.create();

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.15,
    minChildSize: 0.15,
    maxChildSize: 0.85,
    snap: true,
    snapSizes: const [0.15, 0.45, 0.85],
    builder: (context, scrollController) => Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Dimensions.sixteen),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Obx(
        () => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: _dragHandle,
              ).paddingOnly(top: Dimensions.sixteen, bottom: Dimensions.eight),
              _buildBottomSheetContent,
            ],
          ),
        ),
      ),
    ),
  );

  Widget get _dragHandle => Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: Colours.charcoalLight,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget get _buildBottomSheetContent {
    switch (_actionsProvider.selectedAction.value) {
      case ActionType.selectedLocation:
      case ActionType.viewRoute:
        return const SelectedRouteDetailsWidget();
      default:
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaxiActions(),
            Text(
              Get.appLocalizations.nearbyTaxis,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ).paddingOnly(bottom: Dimensions.eight, left: Dimensions.eight),

            _taxiRoutesProvider.nearbyRoutes.isEmpty
                ? const GenericLoader()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _taxiRoutesProvider.nearbyRoutes.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) => NearbyTaxiItemWidget(
                      route: _taxiRoutesProvider.nearbyRoutes[index],
                    ),
                  ),
          ],
        );
    }
  }
}
