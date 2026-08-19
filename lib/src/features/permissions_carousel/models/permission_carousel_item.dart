import 'package:permission_handler/permission_handler.dart';

class PermissionCarouselItem {
  PermissionCarouselItem({
    required this.permission,
    required this.status,
    required this.title,
    required this.description,
    required this.imageAssetPath,
  });
  final Permission permission;
  PermissionStatus status;
  final String title;
  final String description;
  final String imageAssetPath;
}
