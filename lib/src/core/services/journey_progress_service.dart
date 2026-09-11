import 'package:TaxiApp/src/core/models/taxi_journey.dart';
import 'package:TaxiApp/src/core/services/taxi_routing_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class JourneyProgress {
  const JourneyProgress({
    required this.stepIndex,
    required this.distanceToNextStepMeters,
    required this.isComplete,
  });

  final int stepIndex;
  final double distanceToNextStepMeters;
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
        isComplete: true,
      );
    }

    return JourneyProgress(
      stepIndex: stepIndex,
      distanceToNextStepMeters: _remainingDistance(
        location,
        journey.steps[stepIndex],
      ),
      isComplete: false,
    );
  }

  double _remainingDistance(LatLng location, JourneyStep step) {
    if (step.path.length < 2 || step.type != JourneyStepType.taxi) {
      return TaxiRoutingService.distanceBetween(location, step.destination);
    }

    var nearestIndex = 0;
    var nearestDistance = double.infinity;
    for (var index = 0; index < step.path.length; index++) {
      final distance = TaxiRoutingService.distanceBetween(
        location,
        step.path[index],
      );
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = index;
      }
    }

    var remainingDistance = nearestDistance;
    for (var index = nearestIndex + 1; index < step.path.length; index++) {
      remainingDistance += TaxiRoutingService.distanceBetween(
        step.path[index - 1],
        step.path[index],
      );
    }
    return remainingDistance;
  }
}
