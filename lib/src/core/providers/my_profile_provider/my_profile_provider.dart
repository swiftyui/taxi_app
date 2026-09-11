import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

enum SocialSignInProvider { google, facebook, apple }

class MyProfileProvider extends GetxController {
  MyProfileProvider({
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    ImagePicker? imagePicker,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _imagePicker = imagePicker ?? ImagePicker();

  static MyProfileProvider create() => Get.isRegistered<MyProfileProvider>()
      ? Get.find<MyProfileProvider>()
      : Get.put<MyProfileProvider>(MyProfileProvider());

  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final ImagePicker _imagePicker;

  final Rxn<User> user = Rxn<User>();
  final RxBool isBusy = false.obs;
  final RxnString errorMessage = RxnString();
  final RxnString successMessage = RxnString();

  StreamSubscription<User?>? _authSubscription;

  bool get isLoggedIn => user.value != null;

  @override
  void onInit() {
    super.onInit();
    user.value = _auth.currentUser;
    _authSubscription = _auth.userChanges().listen((currentUser) {
      user.value = currentUser;
    });
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) => _runAuthAction(() async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  });

  Future<bool> createAccount({
    required String name,
    required String email,
    required String password,
  }) => _runAuthAction(() async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());
    await credential.user?.sendEmailVerification();
    await credential.user?.reload();
  }, success: 'Account created. Check your email to verify your address.');

  Future<bool> signInWithSocialProvider(SocialSignInProvider provider) =>
      _runAuthAction(() async {
        final authProvider = switch (provider) {
          SocialSignInProvider.google =>
            GoogleAuthProvider()
              ..addScope('email')
              ..addScope('profile'),
          SocialSignInProvider.facebook =>
            FacebookAuthProvider()
              ..addScope('email')
              ..addScope('public_profile'),
          SocialSignInProvider.apple =>
            AppleAuthProvider()
              ..addScope('email')
              ..addScope('name'),
        };

        if (kIsWeb) {
          await _auth.signInWithPopup(authProvider);
        } else {
          await _auth.signInWithProvider(authProvider);
        }
      });

  Future<bool> sendPasswordReset(String email) => _runAuthAction(() async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }, success: 'Password reset instructions have been sent.');

  Future<bool> updateAccountDetails({
    required String name,
    required String email,
  }) => _runAuthAction(() async {
    final currentUser = _requireUser();
    final normalizedName = name.trim();
    final normalizedEmail = email.trim();

    if (normalizedName != (currentUser.displayName ?? '')) {
      await currentUser.updateDisplayName(normalizedName);
    }
    if (normalizedEmail != currentUser.email) {
      await currentUser.verifyBeforeUpdateEmail(normalizedEmail);
    }
    await currentUser.reload();
  }, success: 'Profile updated. Verify your new email if you changed it.');

  Future<bool> updatePassword(String password) => _runAuthAction(() async {
    await _requireUser().updatePassword(password);
  }, success: 'Password updated.');

  Future<bool> sendVerificationEmail() => _runAuthAction(() async {
    await _requireUser().sendEmailVerification();
  }, success: 'Verification email sent.');

  Future<bool> changeProfilePicture() => _runAuthAction(() async {
    final currentUser = _requireUser();
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (image == null) {
      throw const _CancelledProfileAction();
    }

    final bytes = await image.readAsBytes();
    final extension = _fileExtension(image.name);
    final reference = _storage.ref(
      'users/${currentUser.uid}/profile.$extension',
    );
    await reference.putData(
      bytes,
      SettableMetadata(contentType: image.mimeType ?? 'image/$extension'),
    );
    final url = await reference.getDownloadURL();
    await currentUser.updatePhotoURL(url);
    await currentUser.reload();
  }, success: 'Profile picture updated.');

  Future<void> signOut() async {
    await _runAuthAction(_auth.signOut);
  }

  void clearMessages() {
    errorMessage.value = null;
    successMessage.value = null;
  }

  Future<bool> _runAuthAction(
    Future<void> Function() action, {
    String? success,
  }) async {
    if (isBusy.value) {
      return false;
    }

    try {
      isBusy.value = true;
      clearMessages();
      await action();
      user.value = _auth.currentUser;
      user.refresh();
      successMessage.value = success;
      return true;
    } on _CancelledProfileAction {
      return false;
    } on FirebaseAuthException catch (error) {
      errorMessage.value = _authErrorMessage(error);
      return false;
    } on FirebaseException catch (error) {
      errorMessage.value = error.message ?? 'Unable to update your profile.';
      return false;
    } catch (error, stackTrace) {
      debugPrint('Unexpected profile error: $error\n$stackTrace');
      errorMessage.value = 'Something went wrong. Please try again.';
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  User _requireUser() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'not-signed-in',
        message: 'Sign in before changing your profile.',
      );
    }
    return currentUser;
  }

  String _fileExtension(String name) {
    final extension = name.split('.').last.toLowerCase();
    return {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)
        ? extension
        : 'jpg';
  }

  String _authErrorMessage(FirebaseAuthException error) => switch (error.code) {
    'invalid-email' => 'Enter a valid email address.',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'The email address or password is incorrect.',
    'email-already-in-use' => 'An account already uses this email address.',
    'weak-password' => 'Use a stronger password with at least 6 characters.',
    'network-request-failed' => 'Check your internet connection and retry.',
    'too-many-requests' => 'Too many attempts. Please wait and try again.',
    'requires-recent-login' =>
      'For security, sign out and sign in again before making this change.',
    'operation-not-allowed' =>
      'This sign-in method has not been enabled for HambaGo.',
    'popup-closed-by-user' ||
    'web-context-cancelled' => 'Sign-in was cancelled.',
    'account-exists-with-different-credential' =>
      'This email is already linked to another sign-in method.',
    'not-signed-in' => error.message ?? 'Sign in to continue.',
    _ => error.message ?? 'Authentication failed. Please try again.',
  };
}

class _CancelledProfileAction implements Exception {
  const _CancelledProfileAction();
}
