import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/enums/action_type.dart';
import 'package:TaxiApp/src/core/models/taxi_journey.dart';
import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/services/taxi_routing_service.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/widgets/buttons/primary_button.dart';
import 'package:TaxiApp/src/core/widgets/ratings/taxi_ratings.dart';
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
            if (_actionsProvider.selectedAction.value ==
                    ActionType.journeyStarted ||
                _actionsProvider.selectedAction.value ==
                    ActionType.journeyCompleted)
              _LiveGuidanceCard(
                journey: journey,
                stepIndex: _actionsProvider.activeJourneyStepIndex.value,
                distanceToNextStepMeters:
                    _actionsProvider.distanceToNextStepMeters.value,
                isComplete: _actionsProvider.isJourneyComplete.value,
              ),
            Text(
              journey.transferCount == 0
                  ? Get.appLocalizations.directTaxiJourney
                  : '${journey.transferCount} taxi transfer'
                        '${journey.transferCount == 1 ? '' : 's'}',
              style: Get.textTheme.labelLarge?.copyWith(
                color: Colours.charcoalLight,
              ),
            ).paddingOnly(bottom: Dimensions.twelve),
            for (
              var stepIndex = 0;
              stepIndex < journey.steps.length;
              stepIndex++
            )
              _JourneyStepTile(
                step: journey.steps[stepIndex],
                isActive:
                    _actionsProvider.selectedAction.value ==
                        ActionType.journeyStarted &&
                    _actionsProvider.activeJourneyStepIndex.value == stepIndex,
                isComplete:
                    _actionsProvider.selectedAction.value ==
                        ActionType.journeyCompleted ||
                    (_actionsProvider.selectedAction.value ==
                            ActionType.journeyStarted &&
                        stepIndex <
                            _actionsProvider.activeJourneyStepIndex.value),
              ),
            _JourneyNotice(
              icon: Icons.info_outline,
              message: Get.appLocalizations.walkingEstimateNotice,
            ),
            if (journey.listedFares.isNotEmpty)
              Text(
                journey.listedFares.length == 1
                    ? 'Listed fare: '
                          'R${journey.listedFares.single.toStringAsFixed(2)}'
                    : 'Listed route fares: '
                          '${journey.listedFares.map((fare) => 'R${fare.toStringAsFixed(2)}').join(' + ')}',
                style: Get.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).paddingOnly(bottom: Dimensions.twelve),
            Text(
              'Rate your taxi route${journey.taxiLegs.length == 1 ? '' : 's'}',
              style: Get.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).paddingOnly(bottom: Dimensions.eight),
            for (final leg in journey.taxiLegs)
              Container(
                padding: const EdgeInsets.all(Dimensions.twelve),
                margin: const EdgeInsets.only(bottom: Dimensions.eight),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colours.containerOne),
                  borderRadius: BorderRadius.circular(Dimensions.eight),
                ),
                child: TaxiRatings(
                  route: leg.route,
                  title:
                      '${leg.route.properties.originname} to '
                      '${leg.route.properties.destname}',
                ),
              ),
            PrimaryButton(
              text: switch (_actionsProvider.selectedAction.value) {
                ActionType.journeyStarted =>
                  Get.appLocalizations.journeyInProgress,
                ActionType.journeyCompleted =>
                  Get.appLocalizations.journeyComplete,
                _ => Get.appLocalizations.startJourney,
              },
              icon: const Icon(Icons.navigation, color: Colors.white),
              buttonColor: Colours.primaryOne,
              borderColor: Colours.primaryOne,
              enabled:
                  _actionsProvider.selectedAction.value !=
                      ActionType.journeyStarted &&
                  _actionsProvider.selectedAction.value !=
                      ActionType.journeyCompleted,
              onTap: _actionsProvider.startJourney,
            ),
          ],
        ],
      ),
    );
  });
}

class _JourneyStepTile extends StatelessWidget {
  const _JourneyStepTile({
    required this.step,
    required this.isActive,
    required this.isComplete,
  });

  final JourneyStep step;
  final bool isActive;
  final bool isComplete;

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
              : isActive
              ? Colours.green
              : Colours.searchBarBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isComplete
              ? Icons.check
              : step.type == JourneyStepType.taxi
              ? Icons.local_taxi
              : step.type == JourneyStepType.transfer
              ? Icons.transfer_within_a_station
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
                color: isComplete ? Colors.grey : Colors.black,
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

class _LiveGuidanceCard extends StatelessWidget {
  const _LiveGuidanceCard({
    required this.journey,
    required this.stepIndex,
    required this.distanceToNextStepMeters,
    required this.isComplete,
  });

  final TaxiJourney journey;
  final int stepIndex;
  final double distanceToNextStepMeters;
  final bool isComplete;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(Dimensions.twelve),
    margin: const EdgeInsets.only(bottom: Dimensions.sixteen),
    decoration: BoxDecoration(
      color: isComplete
          ? Colours.green.withValues(alpha: 0.12)
          : Colours.yellow.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(Dimensions.eight),
    ),
    child: isComplete
        ? Text(
            Get.appLocalizations.journeyComplete,
            style: Get.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                journey.steps[stepIndex].instruction,
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${TaxiRoutingService.formatDistance(distanceToNextStepMeters)} '
                '${Get.appLocalizations.remaining}',
                style: Get.textTheme.bodySmall,
              ),
            ],
          ),
  );
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
