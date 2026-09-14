import 'package:TaxiApp/src/core/providers/ride_requests_provider/ride_requests_provider.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/nearby_taxi_route_model.dart';
import 'package:TaxiApp/src/core/routes/routes.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/features/landing/widgets/taxi_actions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RideRequestAction extends StatelessWidget {
  RideRequestAction({required this.route, super.key});

  final NearbyTaxiRouteModel route;
  final RideRequestsProvider _provider = RideRequestsProvider.create();

  @override
  Widget build(BuildContext context) => Obx(
    () => TaxiAction(
      label: _provider.isSubmitting.value
          ? 'Requesting ride…'
          : 'Request a ride',
      icon: Icons.local_taxi_rounded,
      onTap: _provider.isSubmitting.value
          ? null
          : () => _confirmRequest(context),
    ),
  );

  Future<void> _confirmRequest(BuildContext context) async {
    if (!_provider.isSignedIn) {
      Get.snackbar(
        'Sign in required',
        'Sign in or create an account before requesting a ride.',
        snackPosition: SnackPosition.BOTTOM,
      );
      await Get.toNamed<void>(AppRoutes.myProfile.value);
      return;
    }

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(
              Icons.local_taxi_rounded,
              color: Colours.blueThree,
            ),
            title: const Text('Request this ride?'),
            content: Text(
              '${route.originName} to ${route.destinationName}\n\n'
              'Nearby drivers will receive your current pickup location.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Request ride'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    final requested = await _provider.requestRide(route);
    if (requested) {
      Get.snackbar(
        'Ride requested',
        'Drivers have been notified. Keep HambaGo open for updates.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Could not request ride',
        _provider.errorMessage.value ?? 'Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
