import 'package:TaxiApp/src/core/providers/my_profile_provider/my_profile_provider.dart';
import 'package:TaxiApp/src/core/providers/route_reviews_provider/route_reviews_provider.dart';
import 'package:TaxiApp/src/core/providers/taxi_routes_provider/models/taxi_route_model.dart';
import 'package:TaxiApp/src/core/routes/routes.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/widgets/loaders/hambago_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';

class TaxiRatings extends StatefulWidget {
  const TaxiRatings({
    required this.route,
    this.title = 'Route rating',
    super.key,
  });

  final TaxiRouteModel route;
  final String title;

  @override
  State<TaxiRatings> createState() => _TaxiRatingsState();
}

class _TaxiRatingsState extends State<TaxiRatings> {
  final RouteReviewsProvider _reviews = RouteReviewsProvider.create();

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void didUpdateWidget(covariant TaxiRatings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route.properties.fid != widget.route.properties.fid) {
      _loadSummary();
    }
  }

  void _loadSummary() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reviews.loadSummary(widget.route);
    });
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final featureId = widget.route.properties.fid;
    final summary = _reviews.summaries[featureId] ?? RouteRatingSummary.empty;
    final isLoading = _reviews.loadingRouteIds.contains(featureId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (isLoading)
              const Expanded(child: RatingShimmer())
            else ...[
              RatingBarIndicator(
                rating: summary.average,
                itemCount: 5,
                itemSize: 20,
                unratedColor: Colors.grey.shade300,
                itemBuilder: (_, _) =>
                    const Icon(Icons.star_rounded, color: Colors.amber),
              ),
              const SizedBox(width: 8),
              Text(
                summary.reviewCount == 0
                    ? 'No reviews yet'
                    : '${summary.average.toStringAsFixed(1)} '
                          '(${summary.reviewCount})',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colours.charcoalLight),
              ),
            ],
            if (!isLoading) ...[
              const Spacer(),
              TextButton.icon(
                onPressed: _openReview,
                icon: const Icon(Icons.rate_review_outlined, size: 16),
                label: Text(
                  summary.userRating == null ? 'Review' : 'Edit review',
                ),
              ),
            ],
          ],
        ),
      ],
    );
  });

  Future<void> _openReview() async {
    if (!MyProfileProvider.create().isLoggedIn) {
      final shouldSignIn = await Get.dialog<bool>(
        AlertDialog(
          title: const _ReviewDialogHeading(
            icon: Icons.rate_review_outlined,
            title: 'Sign in to review',
            subtitle: 'Share useful feedback with other HambaGo travellers.',
          ),
          content: const Text(
            'Sign in so each traveller can submit one fair review per route.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Sign in'),
            ),
          ],
        ),
      );
      if (shouldSignIn == true) {
        await Get.toNamed(AppRoutes.myProfile.value);
      }
      return;
    }

    final summary =
        _reviews.summaries[widget.route.properties.fid] ??
        RouteRatingSummary.empty;
    await Get.dialog<void>(
      _RouteReviewDialog(
        route: widget.route,
        initialRating: summary.userRating ?? 0,
        initialComment: summary.userComment ?? '',
        reviews: _reviews,
      ),
      barrierDismissible: false,
    );
  }
}

class _RouteReviewDialog extends StatefulWidget {
  const _RouteReviewDialog({
    required this.route,
    required this.initialRating,
    required this.initialComment,
    required this.reviews,
  });

  final TaxiRouteModel route;
  final double initialRating;
  final String initialComment;
  final RouteReviewsProvider reviews;

  @override
  State<_RouteReviewDialog> createState() => _RouteReviewDialogState();
}

class _RouteReviewDialogState extends State<_RouteReviewDialog> {
  late double _rating;
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _commentController = TextEditingController(text: widget.initialComment);
    widget.reviews.errorMessage.value = null;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const _ReviewDialogHeading(
      icon: Icons.star_outline_rounded,
      title: 'Review this route',
      subtitle: 'Help other travellers know what to expect.',
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.route.properties.originname} to '
            '${widget.route.properties.destname}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: Dimensions.twelve),
          const Text('How was your experience?'),
          const SizedBox(height: Dimensions.eight),
          RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            itemCount: 5,
            itemSize: 34,
            glow: false,
            allowHalfRating: false,
            unratedColor: Colors.grey.shade300,
            itemBuilder: (_, _) =>
                const Icon(Icons.star_rounded, color: Colors.amber),
            onRatingUpdate: (rating) => setState(() => _rating = rating),
          ),
          const SizedBox(height: Dimensions.twelve),
          TextField(
            controller: _commentController,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Share more (optional)',
              hintText: 'Safety, cleanliness, service, or route experience',
              alignLabelWithHint: true,
            ),
          ),
          Obx(() {
            final error = widget.reviews.errorMessage.value;
            return error == null
                ? const SizedBox.shrink()
                : Text(
                    error,
                    style: const TextStyle(color: Colours.errorColour),
                  );
          }),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: widget.reviews.isSubmitting.value ? null : Get.back,
        child: const Text('Cancel'),
      ),
      Obx(
        () => FilledButton(
          onPressed: widget.reviews.isSubmitting.value || _rating == 0
              ? null
              : _submit,
          child: widget.reviews.isSubmitting.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Publish review'),
        ),
      ),
    ],
  );

  Future<void> _submit() async {
    final saved = await widget.reviews.submitReview(
      route: widget.route,
      rating: _rating,
      comment: _commentController.text,
    );
    if (saved) {
      Get.back<void>();
    }
  }
}

class _ReviewDialogHeading extends StatelessWidget {
  const _ReviewDialogHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFE6F1F5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colours.blueThree, size: 19),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colours.primaryOne,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colours.charcoalLight,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
