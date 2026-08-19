import 'package:permission_handler/permission_handler.dart';

class PermissionCarouselItem {
  PermissionCarouselItem({required this.permission, required this.status});
  final Permission permission;
  final PermissionStatus status;
}
