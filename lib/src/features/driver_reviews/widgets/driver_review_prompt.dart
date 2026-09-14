import 'package:TaxiApp/src/core/models/driver_review.dart';
import 'package:TaxiApp/src/core/providers/driver_reviews_provider/driver_reviews_provider.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DriverReviewPromptHost extends StatefulWidget {
  const DriverReviewPromptHost({super.key});

  @override
  State<DriverReviewPromptHost> createState() => _DriverReviewPromptHostState();
}

class _DriverReviewPromptHostState extends State<DriverReviewPromptHost> {
  final DriverReviewsProvider _provider = DriverReviewsProvider.create();
  Worker? _promptWorker;
  bool _isShowing = false;

  @override
  void initState() {
    super.initState();
    _promptWorker = ever<DriverReviewPrompt?>(_provider.activePrompt, (prompt) {
      if (prompt != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _showPrompt(prompt),
        );
      }
    });
  }

  @override
  void dispose() {
    _promptWorker?.dispose();
    super.dispose();
  }

  Future<void> _showPrompt(DriverReviewPrompt prompt) async {
    if (!mounted || _isShowing || _provider.activePrompt.value != prompt) {
      return;
    }
    _isShowing = true;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DriverReviewSheet(prompt: prompt, provider: _provider),
    );
    _isShowing = false;
    _provider.completePrompt();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class DriverReviewSheet extends StatefulWidget {
  const DriverReviewSheet({
    required this.prompt,
    required this.provider,
    super.key,
  });

  final DriverReviewPrompt prompt;
  final DriverReviewsProvider provider;

  @override
  State<DriverReviewSheet> createState() => _DriverReviewSheetState();
}

class _DriverReviewSheetState extends State<DriverReviewSheet> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    padding: EdgeInsets.fromLTRB(
      18,
      10,
      18,
      MediaQuery.viewInsetsOf(context).bottom + 22,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colours.containerOne,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.sixteen),
          const CircleAvatar(
            radius: 27,
            backgroundColor: Colours.blueThree,
            child: Icon(
              Icons.local_taxi_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: Dimensions.twelve),
          const Text(
            'How was your driver?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colours.primaryOne,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.prompt.originName} → '
            '${widget.prompt.destinationName}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colours.charcoalLight, fontSize: 12),
          ),
          if (widget.prompt.driverLabel.isNotEmpty)
            Text(
              widget.prompt.driverLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colours.blueThree,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ).paddingOnly(top: 3),
          const SizedBox(height: Dimensions.sixteen),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  onPressed: () => setState(() => _rating = star),
                  iconSize: 35,
                  tooltip: '$star star${star == 1 ? '' : 's'}',
                  icon: Icon(
                    star <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: star <= _rating
                        ? Colours.yellow
                        : Colours.containerOne,
                  ),
                ),
            ],
          ),
          Text(
            _rating == 0 ? 'Tap a star to rate' : _ratingLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _rating == 0 ? Colours.charcoalLight : Colours.primaryOne,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Dimensions.sixteen),
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Share your experience (optional)',
              hintText: 'Friendly, safe driving, helpful…',
              alignLabelWithHint: true,
            ),
          ),
          Obx(() {
            final error = widget.provider.errorMessage.value;
            return error == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: Dimensions.eight),
                    child: Text(
                      error,
                      style: const TextStyle(
                        color: Colours.errorColour,
                        fontSize: 11,
                      ),
                    ),
                  );
          }),
          Obx(
            () => SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _rating == 0 || widget.provider.isSubmitting.value
                    ? null
                    : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: Colours.blueThree,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colours.containerOne,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.eight),
                  ),
                ),
                icon: widget.provider.isSubmitting.value
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.reviews_rounded),
                label: Text(
                  widget.provider.isSubmitting.value
                      ? 'Saving review…'
                      : 'Rate driver',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: widget.provider.isSubmitting.value
                ? null
                : () => Navigator.pop(context),
            child: const Text('Not now'),
          ),
        ],
      ),
    ),
  );

  String get _ratingLabel => switch (_rating) {
    1 => 'Needs improvement',
    2 => 'Fair',
    3 => 'Good',
    4 => 'Great',
    _ => 'Excellent',
  };

  Future<void> _submit() async {
    final saved = await widget.provider.submitReview(
      prompt: widget.prompt,
      rating: _rating.toDouble(),
      comment: _commentController.text,
    );
    if (!saved || !mounted) {
      return;
    }
    final awardedPoint = widget.provider.lastReviewAwardedPoint.value;
    Navigator.pop(context);
    Get.snackbar(
      'Thanks for your review',
      awardedPoint
          ? 'Your driver earned 1 HambaPoint.'
          : 'Your feedback helps improve HambaGo.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
