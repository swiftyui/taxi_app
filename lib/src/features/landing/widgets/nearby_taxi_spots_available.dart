import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/nearby_taxi_route_model.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NearbyTaxiSpotsAvailable extends StatelessWidget {
  const NearbyTaxiSpotsAvailable({required this.route, super.key});

  final NearbyTaxiRouteModel route;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${Get.appLocalizations.numberOfSeats}: ${route.model.properties.noofseats}',
        style: Get.textTheme.labelMedium?.copyWith(color: Colors.white),
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
          itemCount: route.model.properties.noofseats,
          itemBuilder: (context, index) => _spotsAvailablePill(
            value: (index + 1).toString(),
            isFilled: false,
          ),
        ),
      ),
    ],
  );

  Widget _spotsAvailablePill({required String value, required bool isFilled}) =>
      Icon(
        Icons.event_seat,
        color: isFilled ? Colours.primaryOne : Colors.grey[300],
      );
}
