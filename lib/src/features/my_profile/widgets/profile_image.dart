import 'package:TaxiApp/src/core/enums/image_list.dart';
import 'package:TaxiApp/src/core/providers/my_profile_provider/my_profile_provider.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class ProfileImage extends StatelessWidget {
  const ProfileImage({this.size = 42, this.editable = false, super.key});

  final double size;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final provider = MyProfileProvider.create();
    return Obx(() {
      final photoUrl = provider.user.value?.photoURL;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colours.red,
                  Colours.yellow,
                  Colours.green,
                  Colors.black,
                ],
              ),
            ),
            child: ClipOval(
              child: ColoredBox(
                color: Colors.white,
                child: photoUrl == null || photoUrl.isEmpty
                    ? SvgPicture.asset(ImageList.appLogo, fit: BoxFit.cover)
                    : Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => SvgPicture.asset(
                          ImageList.appLogo,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
          ),
          if (editable)
            Positioned(
              right: -2,
              bottom: -2,
              child: Material(
                color: Colours.primaryOne,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: provider.isBusy.value
                      ? null
                      : provider.changeProfilePicture,
                  child: const Padding(
                    padding: EdgeInsets.all(7),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
