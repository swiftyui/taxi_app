import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HambaGoShimmer extends StatelessWidget {
  const HambaGoShimmer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: const Color(0xFFE2E5E7),
    highlightColor: const Color(0xFFF7F8F9),
    period: const Duration(milliseconds: 1300),
    child: child,
  );
}

class ShimmerBlock extends StatelessWidget {
  const ShimmerBlock({
    required this.width,
    required this.height,
    this.radius = Dimensions.four,
    super.key,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class TaxiRoutesShimmer extends StatelessWidget {
  const TaxiRoutesShimmer({this.itemCount = 2, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) => HambaGoShimmer(
    child: Column(
      children: List.generate(
        itemCount,
        (_) => Container(
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          padding: const EdgeInsets.all(Dimensions.twelve),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Dimensions.eight),
            border: Border.all(color: Colours.containerOne),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBlock(width: 42, height: 8),
              SizedBox(height: 6),
              ShimmerBlock(width: 190, height: 13),
              SizedBox(height: 12),
              ShimmerBlock(width: 24, height: 8),
              SizedBox(height: 6),
              ShimmerBlock(width: 220, height: 13),
              SizedBox(height: 14),
              Row(
                children: [
                  ShimmerBlock(width: 82, height: 24, radius: 12),
                  SizedBox(width: 8),
                  ShimmerBlock(width: 108, height: 24, radius: 12),
                ],
              ),
              SizedBox(height: 14),
              ShimmerBlock(
                width: double.infinity,
                height: 40,
                radius: Dimensions.eight,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class RatingShimmer extends StatelessWidget {
  const RatingShimmer({super.key});

  @override
  Widget build(BuildContext context) => const HambaGoShimmer(
    child: Row(
      children: [
        ShimmerBlock(width: 112, height: 20, radius: 10),
        SizedBox(width: 8),
        ShimmerBlock(width: 58, height: 12),
      ],
    ),
  );
}
