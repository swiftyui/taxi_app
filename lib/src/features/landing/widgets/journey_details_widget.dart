import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/enums/action_type.dart';
import 'package:TaxiApp/src/core/models/taxi_journey.dart';
import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/routes/routes.dart';
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
              icon:
                  journey.pedestrianSteps.every(
                    (step) => step.hasMappedWalkingRoute,
                  )
                  ? Icons.map_outlined
                  : Icons.info_outline,
              message: _walkingRouteNotice(journey),
            ),
            _FareEstimateCard(
              journey: journey,
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
            _JourneySafetyAction(
              onTap: () => Get.toNamed<void>(AppRoutes.safetyToolkit.value),
            ).paddingOnly(top: Dimensions.eight),
          ],
        ],
      ),
    );
  });

  String _walkingRouteNotice(TaxiJourney journey) {
    final pedestrianSteps = journey.pedestrianSteps.toList(growable: false);
    final mappedCount = pedestrianSteps
        .where((step) => step.hasMappedWalkingRoute)
        .length;
    if (mappedCount == pedestrianSteps.length) {
      return 'Walking paths, distances, and times use Google Maps '
          'pedestrian directions.';
    }
    if (mappedCount > 0) {
      return 'Google Maps pedestrian directions are shown where available. '
          'Remaining walking links are straight-line estimates.';
    }
    return Get.appLocalizations.walkingEstimateNotice;
  }
}

class _JourneySafetyAction extends StatelessWidget {
  const _JourneySafetyAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFEAF2F5),
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: const SizedBox(
        height: 58,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colours.blueThree,
                child: Icon(
                  Icons.health_and_safety_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Safety & journey sharing',
                      style: TextStyle(
                        color: Colours.primaryOne,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Share progress, send SOS, or call 112',
                      style: TextStyle(
                        color: Colours.charcoalLight,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colours.blueThree,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FareEstimateCard extends StatelessWidget {
  const _FareEstimateCard({required this.journey});

  final TaxiJourney journey;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Dimensions.twelve),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFF0D88B)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colours.yellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.payments_outlined,
                color: Colours.primaryOne,
                size: 19,
              ),
            ),
            const SizedBox(width: Dimensions.eight),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated taxi fare',
                    style: TextStyle(
                      color: Colours.primaryOne,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Walking connections are free',
                    style: TextStyle(
                      color: Colours.charcoalLight,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              journey.estimatedFare > 0
                  ? 'R${journey.estimatedFare.toStringAsFixed(2)}'
                  : 'Unavailable',
              style: const TextStyle(
                color: Colours.primaryOne,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const Divider(height: 20, color: Color(0xFFF0D88B)),
        for (var index = 0; index < journey.taxiLegs.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == journey.taxiLegs.length - 1 ? 0 : 7,
            ),
            child: Row(
              children: [
                Text(
                  'Taxi ${index + 1}',
                  style: const TextStyle(
                    color: Colours.charcoalLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    journey.taxiLegs[index].route.properties.destname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colours.primaryOne,
                      fontSize: 10,
                    ),
                  ),
                ),
                Text(
                  journey.taxiLegs[index].route.properties.fare > 0
                      ? 'R${journey.taxiLegs[index].route.properties.fare.toStringAsFixed(2)}'
                      : 'Not listed',
                  style: const TextStyle(
                    color: Colours.primaryOne,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        if (!journey.hasCompleteFareEstimate)
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Colours.charcoalLight,
                size: 14,
              ),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Some route fares are not listed, so the total may be higher.',
                  style: TextStyle(color: Colours.charcoalLight, fontSize: 9),
                ),
              ),
            ],
          ).paddingOnly(top: Dimensions.eight),
        const Text(
          'Confirm the fare with the driver before boarding.',
          style: TextStyle(color: Colours.charcoalLight, fontSize: 9),
        ).paddingOnly(top: Dimensions.eight),
      ],
    ),
  );
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
