import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:flutter/material.dart';

Future<TimeOfDay?> showHambaGoTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) => showDialog<TimeOfDay>(
  context: context,
  barrierColor: Colors.black.withValues(alpha: 0.55),
  builder: (_) => HambaGoTimePicker(initialTime: initialTime),
);

class HambaGoTimePicker extends StatefulWidget {
  const HambaGoTimePicker({required this.initialTime, super.key});

  final TimeOfDay initialTime;

  @override
  State<HambaGoTimePicker> createState() => _HambaGoTimePickerState();
}

class _HambaGoTimePickerState extends State<HambaGoTimePicker> {
  static const double _itemExtent = 48;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              children: [
                const Row(
                  children: [
                    Expanded(child: _PickerLabel(label: 'HOUR')),
                    SizedBox(width: Dimensions.twelve),
                    Expanded(child: _PickerLabel(label: 'MINUTE')),
                  ],
                ),
                const SizedBox(height: Dimensions.eight),
                SizedBox(
                  height: _itemExtent * 3,
                  child: Row(
                    children: [
                      Expanded(
                        child: _TimeWheel(
                          controller: _hourController,
                          itemCount: 24,
                          selectedValue: _hour,
                          onSelected: (value) => setState(() => _hour = value),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          ':',
                          style: TextStyle(
                            color: Colours.primaryOne,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _TimeWheel(
                          controller: _minuteController,
                          itemCount: 60,
                          selectedValue: _minute,
                          onSelected: (value) =>
                              setState(() => _minute = value),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.twenty),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          foregroundColor: Colours.primaryOne,
                          side: const BorderSide(color: Colours.containerOne),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Dimensions.eight,
                            ),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: Dimensions.twelve),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(
                          context,
                          TimeOfDay(hour: _hour, minute: _minute),
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: Colours.blueThree,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Dimensions.eight,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 19),
                        label: const Text(
                          'Use this time',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildHeader() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colours.primaryOne, Colours.blueThree],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.schedule_rounded,
            color: Colours.yellow,
            size: 22,
          ),
        ),
        const SizedBox(width: Dimensions.twelve),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Departure time',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Choose when this taxi leaves',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ),
        Text(
          '${_twoDigits(_hour)}:${_twoDigits(_minute)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ],
    ),
  );

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _PickerLabel extends StatelessWidget {
  const _PickerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: Colours.charcoalLight,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
    ),
  );
}

class _TimeWheel extends StatelessWidget {
  const _TimeWheel({
    required this.controller,
    required this.itemCount,
    required this.selectedValue,
    required this.onSelected,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final int selectedValue;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colours.lightSurface,
      borderRadius: BorderRadius.circular(Dimensions.eight),
      border: Border.all(color: Colours.containerOne),
    ),
    child: ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _HambaGoTimePickerState._itemExtent,
      diameterRatio: 1.45,
      perspective: 0.004,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelected,
      overAndUnderCenterOpacity: 0.35,
      useMagnifier: true,
      magnification: 1.08,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (_, index) => Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 120),
            style: TextStyle(
              color: index == selectedValue
                  ? Colours.blueThree
                  : Colours.charcoalLight,
              fontSize: index == selectedValue ? 20 : 15,
              fontWeight: index == selectedValue
                  ? FontWeight.w800
                  : FontWeight.w500,
            ),
            child: Text(index.toString().padLeft(2, '0')),
          ),
        ),
      ),
    ),
  );
}
