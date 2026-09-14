import 'dart:async';
import 'dart:ui';

import 'package:TaxiApp/src/core/enums/action_type.dart';
import 'package:TaxiApp/src/core/models/emergency_contact.dart';
import 'package:TaxiApp/src/core/providers/actions_provider/actions_provider.dart';
import 'package:TaxiApp/src/core/providers/user_location_provider/user_location_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SafetyProvider extends GetxController {
  SafetyProvider({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static SafetyProvider create() => Get.isRegistered<SafetyProvider>()
      ? Get.find<SafetyProvider>()
      : Get.put<SafetyProvider>(SafetyProvider());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  final RxList<EmergencyContact> contacts = <EmergencyContact>[].obs;
  final Rxn<User> user = Rxn<User>();
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxnString errorMessage = RxnString();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  bool get isSignedIn => user.value != null;
  EmergencyContact? get primaryContact {
    for (final contact in contacts) {
      if (contact.isPrimary) {
        return contact;
      }
    }
    return contacts.isEmpty ? null : contacts.first;
  }

  @override
  void onInit() {
    super.onInit();
    user.value = _auth.currentUser;
    _authSubscription = _auth.userChanges().listen((currentUser) {
      user.value = currentUser;
      unawaited(_subscribe());
    });
    unawaited(_subscribe());
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _subscription?.cancel();
    super.onClose();
  }

  Future<bool> saveContact({
    required String name,
    required String phoneNumber,
    required String relationship,
    required bool isPrimary,
    String? id,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      errorMessage.value = 'Sign in to manage emergency contacts.';
      return false;
    }
    final normalizedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (name.trim().length < 2 ||
        name.trim().length > 80 ||
        normalizedPhone.length < 10 ||
        normalizedPhone.length > 20 ||
        relationship.trim().length > 60) {
      errorMessage.value = 'Enter a valid contact name and phone number.';
      return false;
    }

    try {
      isSaving.value = true;
      errorMessage.value = null;
      final contactId = id ?? DateTime.now().microsecondsSinceEpoch.toString();
      final batch = _firestore.batch();
      if (isPrimary) {
        final existingContacts = await _contacts(user.uid).get();
        for (final contact in existingContacts.docs) {
          if (contact.id != contactId && contact.data()['isPrimary'] == true) {
            batch.update(contact.reference, {
              'isPrimary': false,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
      batch.set(_contacts(user.uid).doc(contactId), {
        'name': name.trim(),
        'phoneNumber': normalizedPhone,
        'relationship': relationship.trim(),
        'isPrimary': isPrimary,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      return true;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to save emergency contact: $error\n$stackTrace');
      errorMessage.value =
          error.message ?? 'Unable to save this emergency contact.';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteContact(EmergencyContact contact) async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    try {
      errorMessage.value = null;
      await _contacts(user.uid).doc(contact.id).delete();
      return true;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to delete emergency contact: $error\n$stackTrace');
      errorMessage.value = error.message ?? 'Unable to delete this contact.';
      return false;
    }
  }

  Future<bool> shareJourney({Rect? shareOrigin}) async {
    final message = await _journeyMessage();
    if (message == null) {
      return false;
    }
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: 'My HambaGo journey',
          sharePositionOrigin: shareOrigin,
        ),
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('Unable to share journey: $error\n$stackTrace');
      errorMessage.value = 'Unable to open the device share sheet.';
      return false;
    }
  }

  Future<bool> sendSos() async {
    final contact = primaryContact;
    if (contact == null) {
      errorMessage.value = 'Add an emergency contact before sending an SOS.';
      return false;
    }
    final message = await _journeyMessage(isSos: true);
    if (message == null) {
      return false;
    }
    try {
      final uri = Uri(
        scheme: 'sms',
        path: contact.phoneNumber,
        queryParameters: {'body': message},
      );
      final launched = await launchUrl(uri);
      if (!launched) {
        errorMessage.value = 'Unable to open your messaging app.';
      }
      return launched;
    } catch (error, stackTrace) {
      debugPrint('Unable to open SOS message: $error\n$stackTrace');
      errorMessage.value = 'Unable to open your messaging app.';
      return false;
    }
  }

  Future<bool> callEmergencyServices() async {
    try {
      final launched = await launchUrl(Uri(scheme: 'tel', path: '112'));
      if (!launched) {
        errorMessage.value = 'Unable to open the phone app.';
      }
      return launched;
    } catch (error, stackTrace) {
      debugPrint('Unable to call emergency services: $error\n$stackTrace');
      errorMessage.value = 'Unable to open the phone app.';
      return false;
    }
  }

  Future<String?> _journeyMessage({bool isSos = false}) async {
    errorMessage.value = null;
    final actions = ActionsProvider.create();
    final journey = actions.journey.value;
    if (journey == null) {
      errorMessage.value = 'Start or plan a journey before sharing it.';
      return null;
    }
    final locationProvider = UserLocationProvider.create();
    final position =
        locationProvider.userLocation.value ??
        await locationProvider.refreshLocation(requestPermission: true);
    if (position == null) {
      errorMessage.value =
          locationProvider.errorMessage.value ??
          'Your current location is unavailable.';
      return null;
    }
    final routeNames = journey.taxiLegs
        .map(
          (leg) =>
              '${leg.route.properties.originname} to '
              '${leg.route.properties.destname}',
        )
        .join(' → ');
    final isActive =
        actions.selectedAction.value == ActionType.journeyStarted &&
        actions.activeJourneyStepIndex.value < journey.steps.length;
    final currentStep = isActive
        ? journey.steps[actions.activeJourneyStepIndex.value].instruction
        : 'Journey planned';
    final prefix = isSos
        ? 'SOS: I may need help during my HambaGo journey.'
        : 'I am travelling with HambaGo.';
    return '$prefix\n'
        'Destination: ${journey.destination.label}\n'
        'Status: $currentStep\n'
        'Taxi route${journey.taxiLegs.length == 1 ? '' : 's'}: $routeNames\n'
        'Current location: https://www.google.com/maps/search/?api=1&query='
        '${position.latitude},${position.longitude}\n'
        'Shared at ${DateTime.now().toLocal()}';
  }

  CollectionReference<Map<String, dynamic>> _contacts(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('emergencyContacts');

  Future<void> _subscribe() async {
    await _subscription?.cancel();
    _subscription = null;
    contacts.clear();
    errorMessage.value = null;
    final user = _auth.currentUser;
    if (user == null) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    _subscription = _contacts(user.uid).snapshots().listen(
      (snapshot) {
        final updatedContacts =
            snapshot.docs
                .map(
                  (document) =>
                      EmergencyContact.fromJson(document.id, document.data()),
                )
                .toList()
              ..sort((left, right) {
                if (left.isPrimary != right.isPrimary) {
                  return left.isPrimary ? -1 : 1;
                }
                return left.name.compareTo(right.name);
              });
        contacts.assignAll(updatedContacts);
        isLoading.value = false;
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Unable to load emergency contacts: $error\n$stackTrace');
        errorMessage.value = 'Unable to load your emergency contacts.';
        isLoading.value = false;
      },
    );
  }
}
