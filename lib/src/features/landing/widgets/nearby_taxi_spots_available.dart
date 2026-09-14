import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/nearby_taxi_route_model.dart';
import 'package:TaxiApp/src/core/providers/route_occupancy_provider/route_occupancy_provider.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NearbyTaxiSpotsAvailable extends StatelessWidget {
  NearbyTaxiSpotsAvailable({required this.route, super.key});

  final NearbyTaxiRouteModel route;
  final RouteOccupancyProvider _occupancyProvider =
      RouteOccupancyProvider.create();

  @override
  Widget build(BuildContext context) => Obx(() {
    final capacity = route.model.properties.noofseats;
    final occupiedSeats = _occupancyProvider
        .occupiedSeats(route.model.properties.fid)
        .clamp(0, capacity);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${Get.appLocalizations.numberOfSeats}: $capacity'
          '${occupiedSeats == 0 ? '' : ' · $occupiedSeats occupied'}',
          style: Get.textTheme.labelMedium?.copyWith(color: Colors.black),
        ).paddingOnly(bottom: Dimensions.four),
        SizedBox(
          width: double.infinity,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              mainAxisSpacing: Dimensions.four,
              crossAxisSpacing: Dimensions.four,
            ),
            itemCount: capacity,
            itemBuilder: (context, index) => _spotsAvailablePill(
              value: (index + 1).toString(),
              isFilled: index < occupiedSeats,
            ),
          ),
        ),
      ],
    );
  });

  Widget _spotsAvailablePill({required String value, required bool isFilled}) =>
      Icon(
        isFilled ? Icons.event_seat_rounded : Icons.event_seat_outlined,
        color: isFilled ? Colours.blueThree : Colors.grey[300],
        semanticLabel: isFilled
            ? 'Occupied seat $value'
            : 'Available seat $value',
      );
}
