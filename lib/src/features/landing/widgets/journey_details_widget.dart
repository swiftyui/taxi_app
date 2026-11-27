import 'dart:math' as math;

import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/enums/action_type.dart';
import 'package:TaxiApp/src/core/models/taxi_journey.dart';
import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/routes/routes.dart';
import 'package:TaxiApp/src/core/services/journey_progress_service.dart';
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
    final action = _actionsProvider.selectedAction.value;
    final previewing = action == ActionType.journeyReady;
    final guiding = action == ActionType.journeyStarted;
    final completed = action == ActionType.journeyCompleted;
    final activeStepIndex = guiding
        ? _actionsProvider.activeJourneyStepIndex
        : 0;

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
          if (!previewing && !guiding && !completed)
            Row(
              children: [
                Expanded(
                  child: Text(
                    destination?.label ??
                        Get.appLocalizations.whereDoYouWantToGo,
                    style: Get.textTheme.titleMedium?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _actionsProvider.clearJourney,
                  icon: const Icon(Icons.close),
                  tooltip: 'Close journey',
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
                  : _actionsProvider.retryJourneyPlanning,
            ),
          ] else if (journey != null) ...[
            if (previewing)
              _JourneyPreviewDetails(
                journey: journey,
                options: _actionsProvider.journeyOptions,
                onSelect: _actionsProvider.selectJourneyOption,
              ),
            if (!previewing)
              Text(
                _journeyType(journey),
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
                isActive: guiding && activeStepIndex == stepIndex,
                isComplete:
                    completed || (guiding && stepIndex < activeStepIndex),
              ),
            _JourneyNotice(
              icon:
                  journey.pedestrianSteps.every(
                    (step) => step.hasMappedWalkingRoute,
                  )
                  ? Icons.map_outlined
                  : Icons.info_outline,
              message: _walkingRouteNotice,
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
            if (!previewing)
              PrimaryButton(
                text:
                    _actionsProvider.selectedAction.value ==
                        ActionType.journeyCompleted
                    ? Get.appLocalizations.journeyComplete
                    : Get.appLocalizations.journeyInProgress,
                icon: const Icon(Icons.navigation, color: Colors.white),
                buttonColor: Colours.primaryOne,
                borderColor: Colours.primaryOne,
                enabled: false,
              ),
            _JourneySafetyAction(
              onTap: () => Get.toNamed<void>(AppRoutes.safetyToolkit.value),
            ).paddingOnly(top: Dimensions.eight),
          ],
        ],
      ),
    );
  });

  String get _walkingRouteNotice => Get.appLocalizations.walkingEstimateNotice;
}

String _journeyType(TaxiJourney journey) => journey.transferCount == 0
    ? Get.appLocalizations.directTaxiJourney
    : '${journey.transferCount} taxi transfer'
          '${journey.transferCount == 1 ? '' : 's'}';

class JourneyPreviewHeader extends StatelessWidget {
  const JourneyPreviewHeader({
    required this.journey,
    required this.recommended,
    required this.dragHandle,
    required this.onStart,
    required this.onClose,
    super.key,
  });

  final TaxiJourney journey;
  final bool recommended;
  final Widget dragHandle;
  final VoidCallback onStart;
  final VoidCallback onClose;

  static const double _handleHeight = 24;
  static const double _metricsHeight = 43;
  static const double _destinationHeight = 25;
  static const double _tripTypeHeight = 19;
  static const double _buttonGap = 10;
  static const double _buttonHeight = 50;

  static double _bottomPadding(BuildContext context) =>
      math.max(12, MediaQuery.viewPaddingOf(context).bottom + 4);

  static double heightFor(BuildContext context) =>
      _handleHeight +
      _metricsHeight +
      _destinationHeight +
      _tripTypeHeight +
      _buttonGap +
      _buttonHeight +
      _bottomPadding(context);

  @override
  Widget build(BuildContext context) => SizedBox(
    height: heightFor(context),
    child: ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, _bottomPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _handleHeight,
              child: Center(child: dragHandle),
            ),
            SizedBox(
              height: _metricsHeight,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '≈ ${journey.estimatedTravelMinutes} min',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colours.primaryOne,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    TaxiRoutingService.formatDistance(
                      journey.totalDistanceMeters,
                    ),
                    style: const TextStyle(
                      color: Colours.charcoalLight,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close journey',
                  ),
                ],
              ),
            ),
            SizedBox(
              height: _destinationHeight,
              child: Text(
                journey.destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colours.primaryOne,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              height: _tripTypeHeight,
              child: Text(
                '${recommended ? 'Recommended · ' : ''}${_journeyType(journey)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colours.charcoalLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: _buttonGap),
            SizedBox(
              height: _buttonHeight,
              child: FilledButton.icon(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: Colours.journeyPurple,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.navigation_rounded, size: 19),
                label: Text(Get.appLocalizations.startJourney),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _JourneyPreviewDetails extends StatelessWidget {
  const _JourneyPreviewDetails({
    required this.journey,
    required this.options,
    required this.onSelect,
  });

  final TaxiJourney journey;
  final List<TaxiJourney> options;
  final ValueChanged<TaxiJourney> onSelect;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: Dimensions.four,
      bottom: Dimensions.twelve,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Travel estimate excludes traffic and taxi wait time.',
          style: TextStyle(color: Colours.charcoalLight, fontSize: 11),
        ),
        if (options.length > 1) ...[
          const SizedBox(height: 7),
          Wrap(
            spacing: Dimensions.eight,
            runSpacing: Dimensions.four,
            children: [
              for (final (index, option) in options.indexed)
                ChoiceChip(
                  label: Text(
                    index == 0 ? 'Recommended' : 'Route ${index + 1}',
                  ),
                  selected: option == journey,
                  selectedColor: const Color(0xFFEDE2FC),
                  labelStyle: const TextStyle(color: Colours.primaryOne),
                  checkmarkColor: Colours.journeyPurple,
                  onSelected: (_) => onSelect(option),
                ),
            ],
          ),
        ],
      ],
    ),
  );
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
          isComplete ? Icons.check : _journeyStepIcon(step.type),
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

IconData _journeyStepIcon(JourneyStepType type) => switch (type) {
  JourneyStepType.walk => Icons.directions_walk_rounded,
  JourneyStepType.taxi => Icons.local_taxi_rounded,
  JourneyStepType.transfer => Icons.transfer_within_a_station_rounded,
};

class JourneyGuidanceHeader extends StatelessWidget {
  const JourneyGuidanceHeader({
    required this.journey,
    required this.progress,
    required this.dragHandle,
    required this.onClose,
    super.key,
  });

  final TaxiJourney journey;
  final JourneyProgress? progress;
  final Widget dragHandle;
  final VoidCallback onClose;

  static const double _handleHeight = 24;
  static const double _gap = 12;
  static const double _instructionSize = 18;
  static const double _captionSize = 12;
  static const double _metricSize = 22;

  static double _instructionHeight(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context);
    return math.max(
      52,
      scale.scale(_instructionSize) * 2.4 +
          scale.scale(_captionSize) * 1.25 +
          7,
    );
  }

  static double _metricsHeight(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context);
    return scale.scale(_metricSize) * 1.2 +
        scale.scale(_captionSize) * 1.25 +
        4;
  }

  static double heightFor(BuildContext context) =>
      _handleHeight +
      _instructionHeight(context) +
      _gap +
      _metricsHeight(context) +
      JourneyPreviewHeader._bottomPadding(context);

  @override
  Widget build(BuildContext context) {
    final l10n = Get.appLocalizations;
    final stepIndex = progress?.stepIndex ?? 0;
    final step = journey.steps.elementAtOrNull(stepIndex);
    final instruction = switch (step) {
      null => l10n.journeyComplete,
      JourneyStep(type: JourneyStepType.walk, hasMappedWalkingRoute: false) =>
        stepIndex == 0 ? l10n.walkToPickup : l10n.walkToDestination,
      _ => step.instruction,
    };
    final nextStopDistance =
        progress?.distanceToNextStepMeters ?? step?.distanceMeters ?? 0;
    final remainingMinutes =
        progress?.remainingMinutes ?? journey.estimatedTravelMinutes;
    final remainingDistance =
        progress?.remainingDistanceMeters ?? journey.totalDistanceMeters;

    return SizedBox(
      height: heightFor(context),
      child: ColoredBox(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            JourneyPreviewHeader._bottomPadding(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: _handleHeight,
                child: Center(child: dragHandle),
              ),
              SizedBox(
                height: _instructionHeight(context),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colours.journeyPurple.withValues(
                        alpha: .10,
                      ),
                      foregroundColor: Colours.journeyPurple,
                      child: Icon(
                        step == null
                            ? Icons.check_rounded
                            : _journeyStepIcon(step.type),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            instruction,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colours.primaryOne,
                              fontSize: _instructionSize,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            step == null
                                ? journey.destination.label
                                : l10n.distanceToNextStop(
                                    TaxiRoutingService.formatDistance(
                                      nextStopDistance,
                                    ),
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _captionStyle,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded, size: 20),
                      tooltip: 'Close journey',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _gap),
              SizedBox(
                height: _metricsHeight(context),
                child: Row(
                  children: [
                    Expanded(
                      child: _metric(
                        remainingMinutes == 0
                            ? '0 min'
                            : '≈ $remainingMinutes min',
                        l10n.remainingTime,
                      ),
                    ),
                    const VerticalDivider(width: 28, indent: 4, endIndent: 4),
                    Expanded(
                      child: _metric(
                        TaxiRoutingService.formatDistance(remainingDistance),
                        l10n.remainingDistance,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _captionStyle = TextStyle(
    color: Colours.charcoalLight,
    fontSize: _captionSize,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );

  Widget _metric(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colours.primaryOne,
          fontSize: _metricSize,
          height: 1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _captionStyle,
      ),
    ],
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
