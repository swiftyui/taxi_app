import 'package:TaxiApp/src/features/permissions_carousel/models/permission_carousel_item.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsCarouselProvider extends GetxController {
  static PermissionsCarouselProvider create() =>
      Get.isRegistered<PermissionsCarouselProvider>()
      ? Get.find<PermissionsCarouselProvider>()
      : Get.put<PermissionsCarouselProvider>(PermissionsCarouselProvider());

  RxList<PermissionCarouselItem> permissions = <PermissionCarouselItem>[].obs;
  RxBool allPermissionsGranted = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializePermissions();
  }

  Future<void> _initializePermissions() async {
    final permissionList = [Permission.location];

    for (final permission in permissionList) {
      final status = await permission.status;
      permissions.add(
        PermissionCarouselItem(permission: permission, status: status),
      );
    }

    if (permissions.every((item) => item.status.isGranted)) {
      allPermissionsGranted.value = true;
    }
  }
}
