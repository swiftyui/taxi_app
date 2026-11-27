import 'dart:math' as math;

import 'package:TaxiApp/src/core/models/taxi_journey.dart';
import 'package:TaxiApp/src/core/services/taxi_routing_service.dart';
import 'package:latlong2/latlong.dart';

class JourneyProgress {
  const JourneyProgress({
    required this.stepIndex,
    required this.distanceToNextStepMeters,
    required this.remainingDistanceMeters,
    required this.remainingMinutes,
    required this.isComplete,
  });

  final int stepIndex;
  final double distanceToNextStepMeters;
  final double remainingDistanceMeters;
  final int remainingMinutes;
  final bool isComplete;
}

class JourneyProgressService {
  const JourneyProgressService();

  JourneyProgress update({
    required TaxiJourney journey,
    required int currentStepIndex,
    required LatLng location,
  }) {
    var stepIndex = currentStepIndex.clamp(0, journey.steps.length);

    while (stepIndex < journey.steps.length) {
      final step = journey.steps[stepIndex];
      final completionRadius = step.type == JourneyStepType.taxi ? 120.0 : 60.0;
      if (TaxiRoutingService.distanceBetween(location, step.destination) >
          completionRadius) {
        break;
      }
      stepIndex++;
    }

    if (stepIndex >= journey.steps.length) {
      return JourneyProgress(
        stepIndex: journey.steps.length,
        distanceToNextStepMeters: 0,
        remainingDistanceMeters: 0,
        remainingMinutes: 0,
        isComplete: true,
      );
    }

    final step = journey.steps[stepIndex];
    final distanceToNextStep = _remainingDistance(location, step);
    var remainingDistance = distanceToNextStep;
    var remainingMinutes = step.estimatedMinutesForDistance(distanceToNextStep);
    for (final futureStep in journey.steps.skip(stepIndex + 1)) {
      remainingDistance += futureStep.distanceMeters;
      remainingMinutes += futureStep.estimatedMinutesForDistance(
        futureStep.distanceMeters,
      );
    }
    return JourneyProgress(
      stepIndex: stepIndex,
      distanceToNextStepMeters: distanceToNextStep,
      remainingDistanceMeters: remainingDistance,
      remainingMinutes: math.max(1, remainingMinutes.ceil()),
      isComplete: false,
    );
  }

  double _remainingDistance(LatLng location, JourneyStep step) {
    if (step.path.length < 2 ||
        (step.type != JourneyStepType.taxi && !step.hasMappedWalkingRoute)) {
      return TaxiRoutingService.distanceBetween(location, step.destination);
    }

    // Use the closest point on a segment so progress changes between vertices.
    final longitudeScale = math.cos(location.latitude * math.pi / 180);
    var nearestDistance = double.infinity;
    var remainingDistance = 0.0;
    var distanceAfterSegment = 0.0;
    for (var index = step.path.length - 1; index > 0; index--) {
      final start = step.path[index - 1];
      final end = step.path[index];
      final dx = (end.longitude - start.longitude) * longitudeScale;
      final dy = end.latitude - start.latitude;
      final x = (location.longitude - start.longitude) * longitudeScale;
      final y = location.latitude - start.latitude;
      final squaredLength = dx * dx + dy * dy;
      final fraction = squaredLength == 0
          ? 0.0
          : ((x * dx + y * dy) / squaredLength).clamp(0.0, 1.0);
      final projected = LatLng(
        start.latitude + fraction * (end.latitude - start.latitude),
        start.longitude + fraction * (end.longitude - start.longitude),
      );
      final distanceFromPath = TaxiRoutingService.distanceBetween(
        location,
        projected,
      );
      final segmentLength = TaxiRoutingService.distanceBetween(start, end);
      if (distanceFromPath <= nearestDistance) {
        nearestDistance = distanceFromPath;
        remainingDistance =
            distanceFromPath +
            (1 - fraction) * segmentLength +
            distanceAfterSegment;
      }
      distanceAfterSegment += segmentLength;
    }

    return remainingDistance;
  }
}
