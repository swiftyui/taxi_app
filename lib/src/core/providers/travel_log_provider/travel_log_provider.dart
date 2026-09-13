import 'dart:async';
import 'dart:convert';

import 'package:TaxiApp/src/core/models/taxi_journey.dart';
import 'package:TaxiApp/src/core/models/travel_log_entry.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TravelLogProvider extends GetxController {
  TravelLogProvider({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    Future<SharedPreferences>? preferences,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _preferences = preferences ?? SharedPreferences.getInstance();

  static TravelLogProvider create() => Get.isRegistered<TravelLogProvider>()
      ? Get.find<TravelLogProvider>()
      : Get.put<TravelLogProvider>(TravelLogProvider());

  static const _storageKeyPrefix = 'travel_log_v1';
  static const _guestStorageKey = '${_storageKeyPrefix}_guest';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Future<SharedPreferences> _preferences;

  final RxList<TravelLogEntry> entries = <TravelLogEntry>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  StreamSubscription<User?>? _authSubscription;
  String? _activeUserId;
  bool _hasLoadedUserScope = false;

  @override
  void onInit() {
    super.onInit();
    unawaited(_handleAuthChange(_auth.currentUser));
    _authSubscription = _auth.userChanges().listen(
      (user) => unawaited(_handleAuthChange(user)),
    );
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  Future<String> recordJourneyStart(TaxiJourney journey) async {
    final startedAt = DateTime.now().toUtc();
    final id = '${startedAt.microsecondsSinceEpoch}';
    final entry = TravelLogEntry.fromJourney(
      id: id,
      journey: journey,
      startedAt: startedAt,
    );
    entries.insert(0, entry);
    await _persist(entry);
    return id;
  }

  Future<void> markJourneyCompleted(String id) async {
    final index = entries.indexWhere((entry) => entry.id == id);
    if (index == -1 || entries[index].status == TravelLogStatus.completed) {
      return;
    }
    final completedEntry = entries[index].completed(DateTime.now().toUtc());
    entries[index] = completedEntry;
    await _persist(completedEntry);
  }

  Future<void> reloadEntries() async {
    await _handleAuthChange(_auth.currentUser, force: true);
  }

  Future<void> _handleAuthChange(User? user, {bool force = false}) async {
    if (!force && _hasLoadedUserScope && _activeUserId == user?.uid) {
      return;
    }
    _hasLoadedUserScope = true;
    _activeUserId = user?.uid;
    final localEntries = await _readLocal(_storageKeyFor(user?.uid));
    if (user == null) {
      _replaceEntries(localEntries);
      return;
    }

    final guestEntries = await _readLocal(_guestStorageKey);
    _replaceEntries([...localEntries, ...guestEntries]);
    await _synchronize(user.uid);
    if (guestEntries.isNotEmpty && errorMessage.value == null) {
      final preferences = await _preferences;
      await preferences.remove(_guestStorageKey);
    }
  }

  Future<List<TravelLogEntry>> _readLocal(String storageKey) async {
    try {
      isLoading.value = true;
      final preferences = await _preferences;
      final encodedEntries = preferences.getStringList(storageKey) ?? [];
      return encodedEntries
          .map(
            (entry) => TravelLogEntry.fromJson(
              Map<String, dynamic>.from(jsonDecode(entry) as Map),
            ),
          )
          .toList(growable: false);
    } catch (error, stackTrace) {
      debugPrint('Unable to load travel history: $error\n$stackTrace');
      errorMessage.value = 'Unable to load your travel history.';
      return const [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _synchronize(String userId) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('travelLogs')
          .get();
      final cloudEntries = snapshot.docs
          .map((document) => TravelLogEntry.fromJson(document.data()))
          .toList(growable: false);
      final merged = <String, TravelLogEntry>{};
      for (final entry in [...cloudEntries, ...entries]) {
        final existing = merged[entry.id];
        if (existing == null ||
            (existing.status == TravelLogStatus.inProgress &&
                entry.status == TravelLogStatus.completed)) {
          merged[entry.id] = entry;
        }
      }
      _replaceEntries(merged.values);
      await Future.wait(entries.map((entry) => _writeCloud(userId, entry)));
      await _writeLocal(_storageKeyFor(userId));
    } catch (error, stackTrace) {
      debugPrint('Unable to sync travel history: $error\n$stackTrace');
      errorMessage.value = 'Travel history could not be synced.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _persist(TravelLogEntry entry) async {
    final user = _auth.currentUser;
    await _writeLocal(_storageKeyFor(user?.uid));
    if (user == null) {
      return;
    }
    try {
      await _writeCloud(user.uid, entry);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to sync travel entry: $error\n$stackTrace');
      errorMessage.value = 'Journey saved on this device but not yet synced.';
    }
  }

  Future<void> _writeCloud(String userId, TravelLogEntry entry) => _firestore
      .collection('users')
      .doc(userId)
      .collection('travelLogs')
      .doc(entry.id)
      .set(entry.toJson());

  Future<void> _writeLocal(String storageKey) async {
    final preferences = await _preferences;
    await preferences.setStringList(
      storageKey,
      entries
          .map((entry) => jsonEncode(entry.toJson()))
          .toList(growable: false),
    );
  }

  String _storageKeyFor(String? userId) =>
      userId == null ? _guestStorageKey : '${_storageKeyPrefix}_$userId';

  void _replaceEntries(Iterable<TravelLogEntry> updatedEntries) {
    final sorted = updatedEntries.toList()
      ..sort((left, right) => right.startedAt.compareTo(left.startedAt));
    entries.assignAll(sorted);
  }
}
