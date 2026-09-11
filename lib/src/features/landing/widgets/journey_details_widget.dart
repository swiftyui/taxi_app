import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/enums/action_type.dart';
import 'package:TaxiApp/src/core/models/taxi_journey.dart';
import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/widgets/buttons/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JourneyDetailsWidget extends StatelessWidget {
  JourneyDetailsWidget({super.key});

  final ActionsProvider _actionsProvider = ActionsProvider.create();

  @override
  Widget build(BuildContext context) => Obx(() {
    final destination = _actionsProvider.selectedDestination.value;
    final journey = _actionsProvider.journey.value;
    final error = _actionsProvider.journeyError.value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.sixteen,
        0,
        Dimensions.sixteen,
        Dimensions.twentyFour,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  destination?.label ?? Get.appLocalizations.whereDoYouWantToGo,
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _actionsProvider.clearJourney,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          if (_actionsProvider.isPlanningJourney.value) ...[
            const LinearProgressIndicator(color: Colours.yellow),
            Text(
              Get.appLocalizations.planningJourney,
            ).paddingOnly(top: Dimensions.sixteen),
          ] else if (error != null) ...[
            _JourneyNotice(icon: Icons.route_outlined, message: error),
            PrimaryButton(
              text: Get.appLocalizations.tryAgain,
              buttonColor: Colours.primaryOne,
              borderColor: Colours.primaryOne,
              onTap: destination == null
                  ? null
                  : () => _actionsProvider.planJourney(destination),
            ),
          ] else if (journey != null) ...[
            Text(
              Get.appLocalizations.bestAvailableJourney,
              style: Get.textTheme.labelLarge?.copyWith(
                color: Colours.charcoalLight,
              ),
            ).paddingOnly(bottom: Dimensions.twelve),
            for (final step in journey.steps) _JourneyStepTile(step: step),
            _JourneyNotice(
              icon: Icons.info_outline,
              message: Get.appLocalizations.walkingEstimateNotice,
            ),
            if (journey.route.properties.fare > 0)
              Text(
                'Listed fare: '
                'R${journey.route.properties.fare.toStringAsFixed(2)}',
                style: Get.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).paddingOnly(bottom: Dimensions.twelve),
            PrimaryButton(
              text:
                  _actionsProvider.selectedAction.value ==
                      ActionType.journeyStarted
                  ? Get.appLocalizations.journeyStarted
                  : Get.appLocalizations.startJourney,
              icon: const Icon(Icons.navigation, color: Colors.white),
              buttonColor: Colours.primaryOne,
              borderColor: Colours.primaryOne,
              enabled:
                  _actionsProvider.selectedAction.value !=
                  ActionType.journeyStarted,
              onTap: _actionsProvider.startJourney,
            ),
          ],
        ],
      ),
    );
  });
}

class _JourneyStepTile extends StatelessWidget {
  const _JourneyStepTile({required this.step});

  final JourneyStep step;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: step.type == JourneyStepType.taxi
              ? Colours.yellow
              : Colours.searchBarBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(
          step.type == JourneyStepType.taxi
              ? Icons.local_taxi
              : Icons.directions_walk,
          color: Colors.black,
        ),
      ).paddingOnly(right: Dimensions.eight),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step.instruction,
              style: Get.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              step.detail,
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colours.charcoalLight,
              ),
            ),
          ],
        ),
      ),
    ],
  ).paddingOnly(bottom: Dimensions.sixteen);
}

class _JourneyNotice extends StatelessWidget {
  const _JourneyNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: Colours.charcoalLight),
      Expanded(
        child: Text(
          message,
          style: Get.textTheme.bodySmall?.copyWith(
            color: Colours.charcoalLight,
          ),
        ).paddingOnly(left: Dimensions.eight),
      ),
    ],
  ).paddingOnly(bottom: Dimensions.sixteen);
}
