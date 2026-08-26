import 'package:TaxiApp/src/core/extensions/typed_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExpandableItem extends StatefulWidget {
  const ExpandableItem({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  State<ExpandableItem> createState() => _ExpandableItemState();
}

class _ExpandableItemState extends State<ExpandableItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: Get.textTheme.labelLarge?.copyWith(color: Colors.black),
            ),
          ),
          RotatedBox(
            quarterTurns: _isExpanded ? 2 : 0,
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.black,
            ),
          ),
        ],
      ).onTap(() => setState(() => _isExpanded = !_isExpanded)),
      _isExpanded ? widget.child : const SizedBox.shrink(),
    ],
  );
}
