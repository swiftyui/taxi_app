import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HambaGoShimmer extends StatelessWidget {
  const HambaGoShimmer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: const Color(0xFFD7E5E9),
    highlightColor: const Color(0xFFF5FAFB),
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
  Widget build(BuildContext context) => Column(
    children: List.generate(itemCount, (_) => const _HambaGoRouteSkeleton()),
  );
}

class SearchRoutesShimmer extends StatelessWidget {
  const SearchRoutesShimmer({this.itemCount = 4, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
    physics: const NeverScrollableScrollPhysics(),
    itemCount: itemCount,
    itemBuilder: (_, index) => const _SearchRouteSkeleton(),
  );
}

class _SearchRouteSkeleton extends StatelessWidget {
  const _SearchRouteSkeleton();

  @override
  Widget build(BuildContext context) => Container(
    height: 82,
    margin: const EdgeInsets.only(bottom: Dimensions.eight),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFDCE7EA)),
      boxShadow: [
        BoxShadow(
          color: Colours.primaryOne.withValues(alpha: 0.07),
          blurRadius: 9,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Row(
      children: [
        Container(
          width: 5,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colours.primaryOne, Colours.blueThree, Colours.yellow],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.twelve),
            child: HambaGoShimmer(
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: Dimensions.twelve),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBlock(width: 190, height: 13, radius: 7),
                        SizedBox(height: 8),
                        ShimmerBlock(
                          width: double.infinity,
                          height: 9,
                          radius: 5,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Dimensions.twelve),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _HambaGoRouteSkeleton extends StatelessWidget {
  const _HambaGoRouteSkeleton();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFDCE7EA)),
      boxShadow: [
        BoxShadow(
          color: Colours.primaryOne.withValues(alpha: 0.08),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Container(
          height: 5,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colours.primaryOne, Colours.blueThree, Colours.yellow],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(Dimensions.twelve),
          child: HambaGoShimmer(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _RoutePathSkeleton(),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBlock(width: 40, height: 7),
                          SizedBox(height: 5),
                          ShimmerBlock(width: 175, height: 12, radius: 6),
                          SizedBox(height: 15),
                          ShimmerBlock(width: 24, height: 7),
                          SizedBox(height: 5),
                          ShimmerBlock(width: 210, height: 12, radius: 6),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    ShimmerBlock(width: 72, height: 24, radius: 12),
                    SizedBox(width: 7),
                    ShimmerBlock(width: 96, height: 24, radius: 12),
                    Spacer(),
                    ShimmerBlock(width: 54, height: 24, radius: 12),
                  ],
                ),
                const SizedBox(height: 12),
                const ShimmerBlock(
                  width: double.infinity,
                  height: 36,
                  radius: 10,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _RoutePathSkeleton extends StatelessWidget {
  const _RoutePathSkeleton();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 14,
    height: 70,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(width: 2, height: 56, color: Colors.white),
        const Positioned(
          top: 2,
          child: Icon(Icons.circle, color: Colors.white, size: 10),
        ),
        const Positioned(
          bottom: 2,
          child: Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
        ),
      ],
    ),
  );
}

class RatingShimmer extends StatelessWidget {
  const RatingShimmer({super.key});

  @override
  Widget build(BuildContext context) => HambaGoShimmer(
    child: Row(
      children: [
        for (var index = 0; index < 5; index++)
          const Padding(
            padding: EdgeInsets.only(right: 2),
            child: Icon(Icons.star_rounded, color: Colors.white, size: 21),
          ),
        const SizedBox(width: 6),
        const ShimmerBlock(width: 48, height: 11),
      ],
    ),
  );
}
