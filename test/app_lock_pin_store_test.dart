import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cashtrack/services/app_lock_pin_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('AppLockPinStore.isValidFormat', () {
    test('accepts exactly four ASCII digits', () {
      expect(AppLockPinStore.isValidFormat('0000'), isTrue);
      expect(AppLockPinStore.isValidFormat('1234'), isTrue);
    });

    test('rejects wrong length, non-digits and whitespace', () {
      for (final bad in ['', '123', '12345', '12a4', ' 1234', '12 4', '১২৩৪']) {
        expect(AppLockPinStore.isValidFormat(bad), isFalse, reason: bad);
      }
    });
  });

  group('AppLockPinStore persistence', () {
    final store = AppLockPinStore.instance;

    test('has no PIN initially', () async {
      expect(await store.read(), isNull);
      expect(await store.hasPin(), isFalse);
      expect(await store.verify('1234'), isFalse);
    });

    test('write / verify / delete round-trip', () async {
      await store.write('4821');
      expect(await store.hasPin(), isTrue);
      expect(await store.verify('4821'), isTrue);
      expect(await store.verify('0000'), isFalse);

      await store.delete();
      expect(await store.hasPin(), isFalse);
      expect(await store.verify('4821'), isFalse);
    });

    test('reads the legacy secure-storage key used by older builds', () async {
      FlutterSecureStorage.setMockInitialValues({'app_lock_pin': '9876'});
      expect(await store.verify('9876'), isTrue);
    });

    test('refuses to persist an invalid PIN', () async {
      expect(() => store.write('12ab'), throwsArgumentError);
      expect(await store.hasPin(), isFalse);
    });
  });

  group('AppLockPinStore attempt limiter', () {
    final store = AppLockPinStore.instance;
    final t0 = DateTime(2026, 11, 20, 10);

    Future<PinVerifyResult> fail(DateTime at) =>
        store.verifyWithLimit('0000', now: at);

    test('lockout schedule escalates and caps at maxLockout', () {
      const d = AppLockPinStore.lockoutAfterFailures;
      expect(d(1), Duration.zero);
      expect(d(4), Duration.zero);
      expect(d(5), const Duration(seconds: 30));
      expect(d(6), const Duration(minutes: 1));
      expect(d(7), const Duration(minutes: 5));
      expect(d(8), const Duration(minutes: 15));
      expect(d(9), AppLockPinStore.maxLockout);
      expect(d(500), AppLockPinStore.maxLockout);
    });

    test('noPin when no PIN is configured', () async {
      final r = await store.verifyWithLimit('1234', now: t0);
      expect(r.status, PinVerifyStatus.noPin);
    });

    test('counts down remaining attempts, then locks out', () async {
      await store.write('2580');
      for (var i = 1; i < AppLockPinStore.freeAttempts; i++) {
        final r = await fail(t0);
        expect(r.status, PinVerifyStatus.incorrect);
        expect(r.attemptsBeforeLockout, AppLockPinStore.freeAttempts - i);
      }
      final locking = await fail(t0);
      expect(locking.status, PinVerifyStatus.lockedOut);
      expect(locking.retryAfter, const Duration(seconds: 30));
    });

    test('during lockout even the correct PIN is rejected unevaluated',
        () async {
      await store.write('2580');
      for (var i = 0; i < AppLockPinStore.freeAttempts; i++) {
        await fail(t0);
      }
      final during = await store.verifyWithLimit('2580',
          now: t0.add(const Duration(seconds: 10)));
      expect(during.status, PinVerifyStatus.lockedOut);
      expect(during.retryAfter, const Duration(seconds: 20));

      // Attempts during lockout must not extend the counter.
      final after = await store.verifyWithLimit('2580',
          now: t0.add(const Duration(seconds: 31)));
      expect(after.status, PinVerifyStatus.success);
    });

    test('next failure after a lockout escalates the lockout', () async {
      await store.write('2580');
      for (var i = 0; i < AppLockPinStore.freeAttempts; i++) {
        await fail(t0);
      }
      final r = await fail(t0.add(const Duration(seconds: 31)));
      expect(r.status, PinVerifyStatus.lockedOut);
      expect(r.retryAfter, const Duration(minutes: 1));
    });

    test('state persists across instances (app restart)', () async {
      await store.write('2580');
      for (var i = 0; i < AppLockPinStore.freeAttempts; i++) {
        await fail(t0);
      }
      // Same backing secure storage, fresh read path.
      expect(
        await store.lockoutRemaining(now: t0.add(const Duration(seconds: 5))),
        const Duration(seconds: 25),
      );
    });

    test('success and resetAttempts clear the counter', () async {
      await store.write('2580');
      for (var i = 0; i < AppLockPinStore.freeAttempts - 1; i++) {
        await fail(t0);
      }
      expect((await store.verifyWithLimit('2580', now: t0)).isSuccess, isTrue);
      // Counter reset: a fresh run of free attempts is available again.
      final r = await fail(t0);
      expect(r.attemptsBeforeLockout, AppLockPinStore.freeAttempts - 1);

      await store.resetAttempts();
      expect((await fail(t0)).attemptsBeforeLockout,
          AppLockPinStore.freeAttempts - 1);
    });

    test('changing the PIN resets the limiter', () async {
      await store.write('2580');
      for (var i = 0; i < AppLockPinStore.freeAttempts; i++) {
        await fail(t0);
      }
      await store.write('1470');
      expect(await store.lockoutRemaining(now: t0), Duration.zero);
    });

    test('clock moved backwards never exceeds maxLockout', () async {
      await store.write('2580');
      for (var i = 0; i < AppLockPinStore.freeAttempts; i++) {
        await fail(t0);
      }
      final remaining = await store.lockoutRemaining(
          now: t0.subtract(const Duration(days: 30)));
      expect(remaining, AppLockPinStore.maxLockout);
    });
  });
}
