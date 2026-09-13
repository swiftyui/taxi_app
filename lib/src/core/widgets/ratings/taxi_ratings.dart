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
              Expanded(
                child: InkWell(
                  onTap: () => _openReviewList(summary),
                  borderRadius: BorderRadius.circular(Dimensions.eight),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RatingBarIndicator(
                        rating: summary.average,
                        itemCount: 5,
                        itemSize: 20,
                        unratedColor: Colors.grey.shade300,
                        itemBuilder: (_, _) =>
                            const Icon(Icons.star_rounded, color: Colors.amber),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          summary.reviewCount == 0
                              ? 'No reviews yet'
                              : '${summary.average.toStringAsFixed(1)} '
                                    '(${summary.reviewCount})',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colours.charcoalLight),
                        ),
                      ),
                      if (summary.reviewCount > 0)
                        const Padding(
                          padding: EdgeInsets.only(left: 3),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Colours.charcoalLight,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            if (!isLoading) ...[
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

  Future<void> _openReviewList(RouteRatingSummary summary) async {
    await Get.bottomSheet<void>(
      _RouteReviewsSheet(route: widget.route, summary: summary),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.sixteen),
        ),
      ),
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
          if (widget.initialRating == 0) ...[
            const SizedBox(height: Dimensions.twelve),
            Container(
              padding: const EdgeInsets.all(Dimensions.eight),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4D6),
                borderRadius: BorderRadius.circular(Dimensions.eight),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.monetization_on_outlined,
                    size: 18,
                    color: Color(0xFF8A5A00),
                  ),
                  SizedBox(width: Dimensions.eight),
                  Expanded(
                    child: Text(
                      'Earn 1 HambaPoint for your first review of this route.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      if (widget.reviews.lastReviewEarnedPoint.value) {
        Get.snackbar(
          'HambaPoint earned',
          'Thanks for helping the HambaGo community. You earned 1 point.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colours.primaryOne,
          colorText: Colors.white,
          margin: const EdgeInsets.all(Dimensions.twelve),
        );
      }
    }
  }
}

class _RouteReviewsSheet extends StatelessWidget {
  const _RouteReviewsSheet({required this.route, required this.summary});

  final TaxiRouteModel route;
  final RouteRatingSummary summary;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colours.containerOne,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.forum_outlined,
                  color: Colours.blueThree,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Traveller reviews',
                        style: TextStyle(
                          color: Colours.primaryOne,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${route.properties.originname} to '
                        '${route.properties.destname}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colours.charcoalLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: Get.back,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (summary.reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                children: [
                  Icon(
                    Icons.star_border_rounded,
                    size: 38,
                    color: Colours.containerOne,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No reviews yet',
                    style: TextStyle(
                      color: Colours.primaryOne,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Be the first traveller to share an experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colours.charcoalLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.all(Dimensions.sixteen),
                itemCount: summary.reviews.length,
                separatorBuilder: (_, _) => const Divider(height: 20),
                itemBuilder: (context, index) =>
                    _ReviewTile(review: summary.reviews[index]),
              ),
            ),
        ],
      ),
    ),
  );
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final RouteReview review;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFFE6F1F5),
        child: Text(
          review.userName.trim().isEmpty
              ? 'H'
              : review.userName.trim()[0].toUpperCase(),
          style: const TextStyle(
            color: Colours.blueThree,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              review.userName,
              style: const TextStyle(
                color: Colours.primaryOne,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            RatingBarIndicator(
              rating: review.rating,
              itemCount: 5,
              itemSize: 16,
              unratedColor: Colors.grey.shade300,
              itemBuilder: (_, _) =>
                  const Icon(Icons.star_rounded, color: Colors.amber),
            ),
            if (review.comment.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                review.comment,
                style: const TextStyle(
                  color: Colours.charcoalLight,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
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
