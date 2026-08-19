import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.text,
    this.buttonColor = Colours.secondary,
    this.textColor = Colors.white,
    this.borderColor = Colors.white,
    this.onTap,
    this.isLoading,
    this.buttonHeight,
    this.buttonWidth,
    this.icon,
    this.enabled = true,
    this.loaderColor,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.borderWidth,
    this.disabledColor,
    super.key,
  });

  final String text;
  final VoidCallback? onTap;
  final Color buttonColor;
  final Color textColor;
  final bool? isLoading;
  final double? buttonWidth;
  final double? buttonHeight;
  final Widget? icon;
  final Color? loaderColor;
  final bool? enabled;
  final Color borderColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final double? borderWidth;
  final Color? disabledColor;

  static const _loaderHeight = 30.0;
  static const _loaderWidth = 20.0;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: borderRadius ?? BorderRadius.circular(Dimensions.eight),
      onTap: enabled == true ? onTap : null,
      child: Ink(
        width: buttonWidth,
        height: buttonHeight,
        decoration: _boxDecoration,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: _buttonContent.paddingSymmetric(
            horizontal: Dimensions.sixteen,
            vertical: Dimensions.eight,
          ),
        ),
      ),
    ),
  );

  Widget get _buttonContent {
    if (isLoading == true) {
      return SizedBox(
        width: _loaderHeight,
        height: _loaderWidth,
        child: SpinKitFadingCircle(
          color: loaderColor ?? Colors.white,
          size: _loaderWidth,
        ),
      );
    } else {
      return _content;
    }
  }

  Widget get _content {
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          icon!.paddingOnly(right: Dimensions.eight),
          Text(
            text,
            style:
                textStyle ??
                Get.textTheme.labelLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    } else {
      return Center(
        child: Text(
          text,
          style:
              textStyle ??
              Get.textTheme.labelLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
  }

  BoxDecoration get _boxDecoration => BoxDecoration(
    color: enabled == true
        ? buttonColor
        : disabledColor ?? buttonColor.withValues(alpha: 0.5),
    borderRadius: borderRadius ?? BorderRadius.circular(Dimensions.eight),
    border: Border.all(color: borderColor, width: borderWidth ?? 1.0),
  );
}
