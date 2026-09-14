import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/widgets/app_bars/custom_app_bar.dart';
import 'package:TaxiApp/src/core/widgets/buttons/primary_button.dart';
import 'package:TaxiApp/src/core/widgets/loaders/generic_loader.dart';
import 'package:TaxiApp/src/features/permissions_carousel/models/permission_carousel_item.dart';
import 'package:TaxiApp/src/features/permissions_carousel/providers/permissions_carousel_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsCarouselScreen extends StatelessWidget {
  PermissionsCarouselScreen({super.key});

  final PermissionsCarouselProvider permissionsCarouselProvider =
      PermissionsCarouselProvider.create();

  @override
  Widget build(BuildContext context) => Obx(() {
    if (permissionsCarouselProvider.permissionsLoaded.value) {
      return DefaultTabController(
        initialIndex: 0,
        length: permissionsCarouselProvider.permissions.length,
        child: Obx(
          () => Scaffold(
            appBar: HambaGoAppBar(
              title: 'HambaGo',
              subtitle: 'A few permissions before you travel',
              showBackButton: false,
              bottom: TabBar(
                padding: EdgeInsets.zero,
                labelPadding: EdgeInsets.zero,
                indicatorPadding: EdgeInsets.zero,
                indicatorColor: Colours.primaryOne,
                tabs: permissionsCarouselProvider.permissions
                    .map(
                      (item) => Tab(
                        iconMargin: EdgeInsets.zero,
                        child: Text(
                          permissionsCarouselProvider.permissions.first.title,
                          style: Get.textTheme.labelLarge?.copyWith(
                            color: Colours.primaryOne,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            body: TabBarView(
              children: permissionsCarouselProvider.permissions
                  .map((item) => _buildTabBar(item: item))
                  .toList(),
            ),
          ),
        ),
      );
    } else {
      return const Scaffold(body: GenericLoader());
    }
  });

  Widget _buildTabBar({required PermissionCarouselItem item}) {
    switch (item.permission) {
      case Permission.location:
        return SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colours.primaryOne.withValues(alpha: 0.6),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: SvgPicture.asset(
                    item.imageAssetPath,
                    fit: BoxFit.contain,
                  ),
                ),
              ).paddingOnly(top: Dimensions.sixteen),
              Text(
                item.title,
                style: Get.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).paddingOnly(top: Dimensions.sixteen, bottom: Dimensions.eight),
              Text(
                item.description,
                style: Get.textTheme.labelLarge?.copyWith(
                  color: Colours.charcoal,
                ),
                textAlign: TextAlign.center,
              ).paddingOnly(bottom: Dimensions.sixteen),
              _buildInformationItem(
                icon: Icons.location_on,
                title: Get.appLocalizations.howYouCanUseLocationServices,
                description:
                    Get.appLocalizations.howToUseLocationServicesDescription,
              ),
              _buildInformationItem(
                icon: Icons.lock,
                title: Get.appLocalizations.howWellUseLocationServices,
                description:
                    Get.appLocalizations.howWellUseLocationServicesDescription,
              ),
              _buildInformationItem(
                icon: Icons.settings,
                title: Get.appLocalizations.howYouCanControlThis,
                description:
                    Get.appLocalizations.howYouCanControlThisDescription,
              ),
              _buildButton(item: item).paddingOnly(
                top: Dimensions.sixteen,
                bottom: Dimensions.sixteen,
                left: Dimensions.sixteen,
                right: Dimensions.sixteen,
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildButton({required PermissionCarouselItem item}) {
    if (item.status != PermissionStatus.granted) {
      return PrimaryButton(
        text: Get.appLocalizations.continueText,
        borderColor: Colours.primaryOne,
        buttonColor: Colours.primaryOne,
        textColor: Colours.onPrimary,
        textStyle: Get.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colours.onPrimary,
        ),
        borderRadius: BorderRadius.circular(Dimensions.four),
        onTap: () async {
          final status = await item.permission.request();
          if (status.isGranted) {
            permissionsCarouselProvider.refreshPermissions();
          } else if (status.isPermanentlyDenied) {
            await openAppSettings();
          }
        },
      );
    } else {
      return PrimaryButton(
        text: Get.appLocalizations.goToSettings,
        borderColor: Colours.blueThree,
        buttonColor: Colors.white,
        textColor: Colours.onPrimary,
        textStyle: Get.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colours.onPrimary,
        ),
        borderRadius: BorderRadius.circular(Dimensions.four),
        onTap: () async {
          await openAppSettings();
        },
      );
    }
  }

  Widget _buildInformationItem({
    required IconData icon,
    required String title,
    required String description,
  }) => Row(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        icon,
        color: Colours.primaryThree,
      ).paddingOnly(right: Dimensions.eight),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Get.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.start,
            ),
            Text(
              description,
              style: Get.textTheme.labelLarge,
              textAlign: TextAlign.start,
            ),
          ],
        ),
      ),
    ],
  ).paddingOnly(bottom: Dimensions.eight);
}
