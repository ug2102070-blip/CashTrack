import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../core/utils/logger.dart';
import '../data/repositories/hive_box_recovery.dart';
import 'encrypted_hive_storage.dart';

/// Owns the binding between on-device financial data and the account it
/// belongs to.
///
/// The app keeps one local data set. Without an owner marker, signing out and
/// signing in as someone else would (a) show the previous user's finances and
/// (b) let sync upload them into the new user's cloud account. This service:
///
/// * records which UID the local data belongs to ([ownerUid]);
/// * decides whether sync may push local data for a UID ([prepareForSync]);
/// * erases all user-scoped local data ([eraseUserData]) while keeping
///   device-level preferences (theme, language, app lock, …).
class LocalUserDataService {
  LocalUserDataService._();
  static final LocalUserDataService instance = LocalUserDataService._();

  static const String _settingsBoxName = 'settingsBox';
  static const String ownerKey = 'localDataOwnerUid';

  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Fires when local data was replaced wholesale (erase, cloud pull, restore)
  /// so in-memory providers can reload from Hive.
  Stream<void> get changes => _changes.stream;

  void notifyChanged() => _changes.add(null);

  /// Device-level preferences that survive an account switch. Everything else
  /// in the settings box is treated as user data and erased — an allow-list,
  /// so newly added user keys are wiped by default instead of leaking.
  @visibleForTesting
  static const Set<String> devicePreferenceKeys = {
    // Appearance / locale
    'darkMode', 'accentColor', 'compactMode', 'language', 'currency',
    'hideAmounts',
    // Notifications
    'notifications', 'budgetAlerts', 'weeklyReport', 'dailyReminderTime',
    // App lock (the lock protects the device, not an account)
    'biometricLock', 'autoLockMinutes', 'appLockPinSet', 'appLockPin',
    'app_lock_pin_failed_attempts', 'app_lock_pin_locked_until_ms',
    'screenshotProtection',
    // Entry/SMS behaviour
    'voiceTransactionInput', 'receiptImageAttachment', 'defaultRecurring',
    'defaultRecurringType', 'monthStartDay', 'rolloverBudget',
    'smsTrack', 'smsMode', 'smsPermissionDialogShown',
    // App lifecycle / auth plumbing (managed by AuthService)
    'onboardingComplete', 'local_auth_session',
  };

  /// Financial data boxes (everything encrypted except settings).
  @visibleForTesting
  static List<String> get financialBoxes => EncryptedHiveStorage.boxes
      .where((name) => name != _settingsBoxName)
      .toList(growable: false);

  Future<Box> _settingsBox() async {
    if (Hive.isBoxOpen(_settingsBoxName)) return Hive.box(_settingsBoxName);
    return Hive.openBox(_settingsBoxName);
  }

  Future<String?> ownerUid() async {
    final value = (await _settingsBox()).get(ownerKey);
    return value is String && value.isNotEmpty ? value : null;
  }

  Future<void> claim(String uid) async {
    await (await _settingsBox()).put(ownerKey, uid);
  }

  /// True when any financial box holds records.
  Future<bool> hasFinancialData() async {
    for (final name in financialBoxes) {
      if (name == 'sync_tombstones') continue;
      final box = await _openBox(name);
      if (box.isNotEmpty) return true;
    }
    return false;
  }

  /// Makes local data safe to sync as [uid]. Returns true if local data was
  /// erased because it belonged to a different account.
  ///
  /// * No owner yet (fresh install, or data from a version before ownership
  ///   tracking): adopted by [uid]. This preserves upgrades, where the data
  ///   belongs to whoever is signed in.
  /// * Owner == [uid]: nothing to do.
  /// * Owner != [uid]: the data belongs to someone else. It is erased — never
  ///   pushed into [uid]'s cloud — before [uid]'s data is pulled.
  Future<bool> prepareForSync(String uid) async {
    final owner = await ownerUid();
    if (owner == uid) return false;
    if (owner == null) {
      await claim(uid);
      return false;
    }
    AppLogger.w('Local data belongs to another account; erasing before sync');
    await eraseUserData();
    await claim(uid);
    return true;
  }

  /// Erases all user-scoped local data: financial boxes, user keys in the
  /// settings box (notes, shopping lists, bills, profile, SMS state, …), the
  /// owner marker, and locally stored receipt images.
  Future<void> eraseUserData() async {
    for (final name in financialBoxes) {
      final box = await _openBox(name);
      await box.clear();
    }

    final settings = await _settingsBox();
    final userKeys = settings.keys
        .where((k) => !devicePreferenceKeys.contains(k.toString()))
        .toList();
    await settings.deleteAll(userKeys);

    await _deleteReceiptImages();
    notifyChanged();
  }

  Future<Box<dynamic>> _openBox(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box<dynamic>(name);
    return openBoxWithRecovery<dynamic>(name);
  }

  Future<void> _deleteReceiptImages() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final receipts = Directory('${dir.path}/receipts');
      if (await receipts.exists()) await receipts.delete(recursive: true);
    } catch (e) {
      // Not fatal for sign-out, but must be visible in logs.
      AppLogger.e('Failed to delete local receipt images: $e');
    }
  }
}
