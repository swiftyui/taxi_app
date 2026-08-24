import 'package:TaxiApp/src/core/enums/image_list.dart';
import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/extensions/rx_worker.dart';
import 'package:TaxiApp/src/core/routes/routes.dart';
import 'package:TaxiApp/src/features/permissions_carousel/models/permission_carousel_item.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsCarouselProvider extends GetxController with RxWorkerMixin {
  static PermissionsCarouselProvider create() =>
      Get.isRegistered<PermissionsCarouselProvider>()
      ? Get.find<PermissionsCarouselProvider>()
      : Get.put<PermissionsCarouselProvider>(PermissionsCarouselProvider());

  RxList<PermissionCarouselItem> permissions = <PermissionCarouselItem>[].obs;
  RxBool allPermissionsGranted = false.obs;
  RxBool permissionsLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializePermissions();
    everWithDisposal(
      allPermissionsGranted,
      (value) => Get.toNamed(AppRoutes.root.value),
    );
  }

  Future<void> _initializePermissions() async {
    permissionsLoaded.value = false;
    final permissionList = [Permission.location];

    for (final permission in permissionList) {
      final status = await permission.status;
      switch (permission) {
        case Permission.location:
          permissions.add(
            PermissionCarouselItem(
              permission: permission,
              status: status,
              title: Get.appLocalizations.accessToLocation,
              description: Get.appLocalizations.locationPermissionsDescription,
              imageAssetPath: ImageList.taxiIcon,
            ),
          );
          break;
        default:
          break;
      }
    }

    if (permissions.every((item) => item.status.isGranted)) {
      allPermissionsGranted.value = true;
    }
    permissionsLoaded.value = true;
  }

  Future<void> refreshPermissions() async {
    for (final item in permissions) {
      final status = await item.permission.status;
      item.status = status;
    }

    if (permissions.every((item) => item.status.isGranted)) {
      allPermissionsGranted.value = true;
    }
  }
}
