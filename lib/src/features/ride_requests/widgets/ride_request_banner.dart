import 'package:TaxiApp/src/core/providers/ride_requests_provider/ride_requests_provider.dart';
import 'package:TaxiApp/src/core/routes/routes.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RideRequestBanner extends StatelessWidget {
  RideRequestBanner({super.key});

  final RideRequestsProvider _provider = RideRequestsProvider.create();

  @override
  Widget build(BuildContext context) => Obx(() {
    final request = _provider.bannerRequest.value;
    if (request == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: InkWell(
              onTap: () {
                _provider.dismissBanner();
                Get.toNamed<void>(AppRoutes.rideRequests.value);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colours.primaryOne,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Colours.blueThree,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_pin_circle_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${request.riderName} needs a ride',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${request.originName} → '
                                  '${request.destinationName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _provider.dismissBanner();
                              Get.toNamed<void>(AppRoutes.rideRequests.value);
                            },
                            child: const Text(
                              'VIEW',
                              style: TextStyle(color: Colours.yellow),
                            ),
                          ),
                          IconButton(
                            onPressed: _provider.dismissBanner,
                            tooltip: 'Dismiss',
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    LinearProgressIndicator(
                      value: _provider.bannerProgress.value.clamp(0, 1),
                      minHeight: 4,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colours.yellow,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  });
}
