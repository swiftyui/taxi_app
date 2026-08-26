import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';

class TaxiRatings extends StatelessWidget {
  const TaxiRatings({super.key});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        Get.appLocalizations.taxiRating,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: Colors.black),
      ),
      RatingBar.builder(
        initialRating: 3,
        minRating: 1,
        direction: Axis.horizontal,
        allowHalfRating: true,
        itemCount: 5,
        itemBuilder: (context, _) => const Icon(
          Icons.star,
          color: Colors.amber,
          size: Dimensions.sixteen,
        ),
        onRatingUpdate: (rating) {},
        glow: true,
        glowColor: Colors.amberAccent,
        glowRadius: 4,
        itemSize: 24,
        maxRating: 5,
      ),
    ],
  );
}
