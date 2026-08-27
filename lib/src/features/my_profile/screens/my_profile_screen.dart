import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/providers/my_profile_provider/my_profile_provider.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  final MyProfileProvider _myProfileProvider = MyProfileProvider.create();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(Get.appLocalizations.myProfile)),
    body: Obx(() => _buildBody),
  );

  Widget get _buildBody {
    if (_myProfileProvider.isLoggedIn.value) {
      return Center(child: Text(Get.appLocalizations.myProfile));
    } else {
      return Center(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Dimensions.eight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 2,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'asdasdasdsa',
                style: Get.textTheme.labelLarge?.copyWith(color: Colors.black),
              ),
            ],
          ),
        ),
      ).paddingAll(Dimensions.sixteen);
    }
  }
}
