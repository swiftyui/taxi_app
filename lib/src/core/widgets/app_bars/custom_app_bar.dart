import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HambaGoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HambaGoAppBar({
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.leadingIcon = Icons.arrow_back_rounded,
    this.onBackPressed,
    this.actions = const [],
    this.bottom,
    this.backgroundColor = Colours.lightSurface,
    super.key,
  });

  static const double toolbarHeight = 68;

  final String title;
  final String? subtitle;
  final bool showBackButton;
  final IconData leadingIcon;
  final VoidCallback? onBackPressed;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final Color backgroundColor;

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    toolbarHeight: toolbarHeight,
    backgroundColor: backgroundColor,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    centerTitle: false,
    leadingWidth: showBackButton ? 58 : 12,
    leading: showBackButton
        ? Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Center(
              child: _AppBarSurface(
                size: 40,
                shape: BoxShape.circle,
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (onBackPressed != null) {
                      onBackPressed!();
                    } else {
                      Get.back<void>();
                    }
                  },
                  tooltip: leadingIcon == Icons.close_rounded
                      ? 'Close'
                      : 'Back',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  icon: Icon(leadingIcon, color: Colours.primaryOne, size: 20),
                ),
              ),
            ),
          )
        : const SizedBox.shrink(),
    titleSpacing: showBackButton ? 10 : 4,
    title: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colours.primaryOne,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 1),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colours.charcoalLight,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    ),
    actions: actions,
    bottom: bottom,
  );
}

class HambaGoAppBarAction extends StatelessWidget {
  const HambaGoAppBarAction({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.badgeCount = 0,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final int badgeCount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: Dimensions.twelve),
    child: Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _AppBarSurface(
            size: 40,
            borderRadius: BorderRadius.circular(11),
            child: IconButton(
              onPressed: onPressed,
              tooltip: tooltip,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              icon: Icon(icon, color: Colours.blueThree, size: 20),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colours.red,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _AppBarSurface extends StatelessWidget {
  const _AppBarSurface({
    required this.size,
    required this.child,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
  });

  final double size;
  final Widget child;
  final BoxShape shape;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: shape,
      borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
      boxShadow: [
        BoxShadow(
          color: Colours.primaryOne.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}
