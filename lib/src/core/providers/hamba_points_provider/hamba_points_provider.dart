import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class HambaPointsProvider extends GetxController {
  HambaPointsProvider({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static HambaPointsProvider create() => Get.isRegistered<HambaPointsProvider>()
      ? Get.find<HambaPointsProvider>()
      : Get.put<HambaPointsProvider>(HambaPointsProvider());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  final RxInt points = 0.obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  StreamSubscription<User?>? _authSubscription;

  @override
  void onInit() {
    super.onInit();
    _authSubscription = _auth.userChanges().listen((user) {
      if (user == null) {
        points.value = 0;
      } else {
        unawaited(reloadPoints());
      }
    });
    if (_auth.currentUser != null) {
      unawaited(reloadPoints());
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  Future<void> reloadPoints() async {
    final user = _auth.currentUser;
    if (user == null) {
      points.value = 0;
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('hambaPointAwards')
          .get();
      points.value = snapshot.docs.fold(
        0,
        (total, document) => total + (document.data()['points'] as int? ?? 0),
      );
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to load HambaPoints: $error\n$stackTrace');
      errorMessage.value = 'Unable to load HambaPoints.';
    } finally {
      isLoading.value = false;
    }
  }
}
