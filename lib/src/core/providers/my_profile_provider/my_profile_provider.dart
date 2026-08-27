import 'package:get/get.dart';

class MyProfileProvider extends GetxController {
  MyProfileProvider();

  static MyProfileProvider create() => Get.isRegistered<MyProfileProvider>()
      ? Get.find<MyProfileProvider>()
      : Get.put<MyProfileProvider>(MyProfileProvider());

  final RxBool isLoggedIn = false.obs;
}
