import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:cashtrack/services/account_session_service.dart';
import 'package:cashtrack/services/auth_service.dart';
import 'package:cashtrack/services/local_user_data_service.dart';
import 'package:cashtrack/services/sync_service.dart';

import 'hive_test_setup.dart';

class _FakeUser implements User {
  _FakeUser({this.anonymous = false});
  final bool anonymous;
  @override
  bool get isAnonymous => anonymous;
  @override
  String get uid => anonymous ? 'anon-uid' : 'user-a';
  int tokenRefreshes = 0;
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    if (forceRefresh) tokenRefreshes++;
    return 'token';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuth implements AuthService {
  _FakeAuth(this.user, {this.signOutError});
  final User? user;
  final Object? signOutError;
  final calls = <String>[];

  @override
  User? get currentUser => user;

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    if (signOutError != null) throw signOutError!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSync implements SyncService {
  _FakeSync(this.result);
  final String result;
  int calls = 0;

  @override
  Future<String> backupToCloud() async {
    calls++;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final service = LocalUserDataService.instance;

  setUpAll(() async {
    await initializeHiveForTests();
    for (final name in [
      'settingsBox',
      ...LocalUserDataService.financialBoxes
    ]) {
      if (!Hive.isBoxOpen(name)) await Hive.openBox(name);
    }
  });

  setUp(() async {
    for (final name in [
      'settingsBox',
      ...LocalUserDataService.financialBoxes
    ]) {
      await Hive.box(name).clear();
    }
  });

  Future<void> seedUserData() async {
    await Hive.box('transactions').put('t1', {'id': 't1', 'amount': 5000});
    await Hive.box('accounts').put('a1', {'id': 'a1', 'name': 'bKash'});
    await Hive.box('sync_tombstones').put('x', {'id': 'x'});
    final settings = Hive.box('settingsBox');
    // Device preferences — must survive.
    await settings.put('darkMode', true);
    await settings.put('language', 'bn');
    await settings.put('appLockPinSet', true);
    // User data — must be erased.
    await settings.put('notes_list_v1', '[{"text":"salary"}]');
    await settings.put('shopping_planner_lists_v1', '[]');
    await settings.put('utility_bills_list_v1', '[]');
    await settings.put('profile_user-a_full_name', 'Rahim');
    await settings.put('pinnedAccounts', ['a1']);
    await settings.put('dailyBudgetLimit', 50000);
    await settings.put('lastCloudBackupAt', '2026-11-20T00:00:00Z');
    await settings.put('recurring_processed_r1_2026-11-20', true);
  }

  group('eraseUserData', () {
    test('clears financial boxes and user keys, keeps device preferences',
        () async {
      await seedUserData();
      await service.claim('user-a');

      await service.eraseUserData();

      for (final name in LocalUserDataService.financialBoxes) {
        expect(Hive.box(name).isEmpty, isTrue, reason: name);
      }
      final settings = Hive.box('settingsBox');
      expect(settings.get('darkMode'), true);
      expect(settings.get('language'), 'bn');
      expect(settings.get('appLockPinSet'), true);
      for (final key in [
        'notes_list_v1',
        'shopping_planner_lists_v1',
        'utility_bills_list_v1',
        'profile_user-a_full_name',
        'pinnedAccounts',
        'dailyBudgetLimit',
        'lastCloudBackupAt',
        'recurring_processed_r1_2026-11-20',
        LocalUserDataService.ownerKey,
      ]) {
        expect(settings.containsKey(key), isFalse, reason: key);
      }
    });

    test('unknown (future) settings keys are erased by default', () async {
      await Hive.box('settingsBox').put('some_new_user_feature_v1', 'x');
      await service.eraseUserData();
      expect(Hive.box('settingsBox').containsKey('some_new_user_feature_v1'),
          isFalse);
    });

    test('deletes locally stored receipt images', () async {
      final docs = await Directory.systemTemp.createTemp('ct_docs_');
      addTearDown(() => docs.delete(recursive: true));
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => docs.path);
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null));

      final receipt = File('${docs.path}/receipts/r1.jpg');
      await receipt.create(recursive: true);
      await service.eraseUserData();
      expect(await Directory('${docs.path}/receipts').exists(), isFalse);
    });

    test('notifies listeners so providers reload', () async {
      final fired = expectLater(service.changes, emits(null));
      await service.eraseUserData();
      await fired;
    });
  });

  group('prepareForSync', () {
    test('adopts unowned data (upgrade from older version)', () async {
      await seedUserData();
      final erased = await service.prepareForSync('user-a');
      expect(erased, isFalse);
      expect(await service.ownerUid(), 'user-a');
      expect(Hive.box('transactions').isNotEmpty, isTrue);
    });

    test('keeps data owned by the same account', () async {
      await seedUserData();
      await service.claim('user-a');
      expect(await service.prepareForSync('user-a'), isFalse);
      expect(Hive.box('transactions').isNotEmpty, isTrue);
    });

    test('erases another account\'s data instead of syncing it', () async {
      await seedUserData();
      await service.claim('user-a');

      final erased = await service.prepareForSync('user-b');

      expect(erased, isTrue);
      expect(Hive.box('transactions').isEmpty, isTrue);
      expect(Hive.box('accounts').isEmpty, isTrue);
      expect(await service.ownerUid(), 'user-b');
    });
  });

  group('AccountSessionService', () {
    test('classifies account kinds', () {
      expect(AccountSessionService(auth: _FakeAuth(_FakeUser())).currentKind,
          AccountKind.registered);
      expect(
          AccountSessionService(auth: _FakeAuth(_FakeUser(anonymous: true)))
              .currentKind,
          AccountKind.guest);
      expect(AccountSessionService(auth: _FakeAuth(null)).currentKind,
          AccountKind.localOnly);
    });

    test('backup result mapping for registered accounts', () async {
      final ok = _FakeSync(SyncService.syncCompleteMessage);
      expect(
          await AccountSessionService(auth: _FakeAuth(_FakeUser()), sync: ok)
              .backupBeforeSignOut(),
          SignOutBackupResult.backedUp);

      final failing = _FakeSync('Sync failed: offline');
      expect(
          await AccountSessionService(
                  auth: _FakeAuth(_FakeUser()), sync: failing)
              .backupBeforeSignOut(),
          SignOutBackupResult.failed);
    });

    test('guests are never "backed up" (their cloud copy is unreachable)',
        () async {
      final sync = _FakeSync(SyncService.syncCompleteMessage);
      final result = await AccountSessionService(
              auth: _FakeAuth(_FakeUser(anonymous: true)), sync: sync)
          .backupBeforeSignOut();
      expect(result, SignOutBackupResult.notAvailable);
      expect(sync.calls, 0);
    });

    test('erases local data before signing out', () async {
      await seedUserData();
      final auth = _FakeAuth(_FakeUser());
      await AccountSessionService(auth: auth).eraseLocalDataAndSignOut();
      expect(auth.calls, ['signOut']);
      expect(Hive.box('transactions').isEmpty, isTrue);
    });

    test('data stays erased even if sign-out itself fails', () async {
      await seedUserData();
      final auth = _FakeAuth(_FakeUser(), signOutError: Exception('net'));
      await expectLater(
        AccountSessionService(auth: auth).eraseLocalDataAndSignOut(),
        throwsException,
      );
      expect(Hive.box('transactions').isEmpty, isTrue);
    });
  });

  group('AccountSessionService.deleteAccount', () {
    test('server first, then erase + sign out; refreshes the ID token',
        () async {
      await seedUserData();
      final user = _FakeUser();
      final auth = _FakeAuth(user);
      final order = <String>[];
      final session = AccountSessionService(
        auth: auth,
        deleteAccountCall: () async {
          order.add('server');
          // Local data must still exist when the server call runs.
          expect(Hive.box('transactions').isNotEmpty, isTrue);
        },
      );

      expect(await session.deleteAccount(), DeleteAccountResult.deleted);
      expect(order, ['server']);
      expect(user.tokenRefreshes, 1);
      expect(auth.calls, ['signOut']);
      expect(Hive.box('transactions').isEmpty, isTrue);
    });

    test('server failure leaves local data and session untouched', () async {
      await seedUserData();
      final auth = _FakeAuth(_FakeUser());
      final session = AccountSessionService(
        auth: auth,
        deleteAccountCall: () async => throw FirebaseFunctionsException(
            code: 'unavailable', message: 'offline'),
      );

      expect(await session.deleteAccount(), DeleteAccountResult.failed);
      expect(auth.calls, isEmpty);
      expect(Hive.box('transactions').isNotEmpty, isTrue);
    });

    test('stale sign-in maps to requiresRecentLogin', () async {
      await seedUserData();
      final session = AccountSessionService(
        auth: _FakeAuth(_FakeUser()),
        deleteAccountCall: () async => throw FirebaseFunctionsException(
            code: 'failed-precondition', message: 'requires-recent-login'),
      );
      expect(await session.deleteAccount(),
          DeleteAccountResult.requiresRecentLogin);
      expect(Hive.box('transactions').isNotEmpty, isTrue);
    });

    test('client-side requires-recent-login maps to re-auth prompt', () async {
      await seedUserData();
      final auth = _FakeAuth(_FakeUser());
      final session = AccountSessionService(
        auth: auth,
        deleteAccountCall: () async =>
            throw FirebaseAuthException(code: 'requires-recent-login'),
      );
      expect(await session.deleteAccount(),
          DeleteAccountResult.requiresRecentLogin);
      expect(auth.calls, isEmpty);
      expect(Hive.box('transactions').isNotEmpty, isTrue);
    });

    test('Firestore/network error during deletion keeps local data', () async {
      await seedUserData();
      final session = AccountSessionService(
        auth: _FakeAuth(_FakeUser()),
        deleteAccountCall: () async => throw FirebaseException(
            plugin: 'cloud_firestore', code: 'unavailable'),
      );
      expect(await session.deleteAccount(), DeleteAccountResult.failed);
      expect(Hive.box('transactions').isNotEmpty, isTrue);
    });

    test('a sign-out error after server deletion still reports deleted',
        () async {
      await seedUserData();
      final session = AccountSessionService(
        auth: _FakeAuth(_FakeUser(), signOutError: Exception('x')),
        deleteAccountCall: () async {},
      );
      expect(await session.deleteAccount(), DeleteAccountResult.deleted);
      expect(Hive.box('transactions').isEmpty, isTrue);
    });
  });
}
