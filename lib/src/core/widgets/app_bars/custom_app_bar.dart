import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/theme/constants/font_sizes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBar extends AppBar {
  CustomAppBar({
    this.backButton = false,
    this.menuButton = false,
    this.onMenuButtonPressed,
    this.titleText,
    this.titleWidget,
    this.onBackButtonPressed,
    super.key,
    super.actions,
    super.bottom,
  }) : super(
         forceMaterialTransparency: false,
         shadowColor: Colors.black,
         systemOverlayStyle: SystemUiOverlayStyle.dark,
         leading: null,
         automaticallyImplyLeading: false,
         backgroundColor: Theme.of(Get.context!).colorScheme.surface,
         actionsIconTheme: IconThemeData(color: Get.colorScheme.onSurface),
         toolbarHeight: kIsWeb ? 64 : kToolbarHeight,
         clipBehavior: Clip.none,
         title:
             Row(
               crossAxisAlignment: CrossAxisAlignment.center,
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 backButton
                     ? Expanded(
                         child: Row(
                           children: [
                             InkWell(
                               borderRadius: BorderRadius.circular(99),
                               onTap: () {
                                 HapticFeedback.mediumImpact();
                                 if (onBackButtonPressed != null) {
                                   onBackButtonPressed();
                                 } else {
                                   Get.back();
                                 }
                               },
                               child: Icon(
                                 Icons.arrow_back_ios_new_rounded,
                                 color: Get.colorScheme.secondary,
                                 size: Dimensions.sixteen,
                               ).paddingAll(Dimensions.eight),
                             ).paddingOnly(right: Dimensions.eight),
                             titleText == null && titleWidget == null
                                 ? Text(
                                     'HambaGo',
                                     style: GoogleFonts.barriecito().copyWith(
                                       color: Get.theme.colorScheme.onSurface,
                                       fontSize: FontSize.twentyFour,
                                       fontWeight: FontWeight.w100,
                                     ),
                                   )
                                 : titleWidget ??
                                       Expanded(
                                         child: Text(
                                           titleText ?? '',
                                           style: GoogleFonts.barriecito()
                                               .copyWith(
                                                 color: Get
                                                     .theme
                                                     .colorScheme
                                                     .onSurface,
                                                 fontSize: FontSize.twentyFour,
                                                 fontWeight: FontWeight.w100,
                                               ),
                                         ),
                                       ),
                           ],
                         ),
                       )
                     : Expanded(
                         child: Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           crossAxisAlignment: CrossAxisAlignment.center,
                           children: [
                             const Spacer(),
                             titleText == null && titleWidget == null
                                 ? Text(
                                     'HambaGo',
                                     style: GoogleFonts.barriecito().copyWith(
                                       color: Get.theme.colorScheme.onSurface,
                                       fontSize: FontSize.twentyFour,
                                       fontWeight: FontWeight.w100,
                                     ),
                                   )
                                 : titleWidget ??
                                       Expanded(
                                         child: Text(
                                           titleText ?? '',
                                           style: GoogleFonts.barriecito()
                                               .copyWith(
                                                 color: Get
                                                     .theme
                                                     .colorScheme
                                                     .onSurface,
                                                 fontSize: FontSize.twentyFour,
                                                 fontWeight: FontWeight.w100,
                                               ),
                                         ),
                                       ),
                             const Spacer(),
                           ],
                         ),
                       ),
                 menuButton
                     ? InkWell(
                         borderRadius: BorderRadius.circular(99),
                         onTap: () {
                           HapticFeedback.mediumImpact();
                           onMenuButtonPressed?.call();
                         },
                         child: Icon(
                           Icons.settings,
                           color: Get.colorScheme.secondary,
                           size: Dimensions.sixteen,
                         ).paddingAll(Dimensions.eight),
                       ).paddingOnly(right: Dimensions.eight)
                     : const SizedBox.shrink(),
               ],
             ).paddingOnly(
               top: Dimensions.sixteen,
               bottom: Dimensions.sixteen,
               left: Dimensions.eight,
             ),
       );
  final VoidCallback? onMenuButtonPressed;
  final bool menuButton;
  final bool backButton;
  final String? titleText;
  final Widget? titleWidget;
  final VoidCallback? onBackButtonPressed;
}
