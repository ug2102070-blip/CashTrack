import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// Outcome of a rate-limited PIN check.
enum PinVerifyStatus {
  /// PIN matched; the failure counter has been reset.
  success,

  /// PIN did not match; see [PinVerifyResult.attemptsBeforeLockout].
  incorrect,

  /// Too many failures; the candidate was NOT evaluated.
  /// See [PinVerifyResult.retryAfter].
  lockedOut,

  /// No PIN is configured.
  noPin,
}

class PinVerifyResult {
  const PinVerifyResult(
    this.status, {
    this.retryAfter,
    this.attemptsBeforeLockout,
  });

  final PinVerifyStatus status;

  /// Remaining lockout time when [status] is [PinVerifyStatus.lockedOut], or
  /// when an [PinVerifyStatus.incorrect] attempt just triggered a lockout.
  final Duration? retryAfter;

  /// Wrong attempts left before the next lockout (only for `incorrect`).
  final int? attemptsBeforeLockout;

  bool get isSuccess => status == PinVerifyStatus.success;
}

/// Single source of truth for the app-lock PIN and its brute-force limiter.
///
/// Mobile/desktop: stored in the platform secure store (Keystore/Keychain).
/// Web: no secure store exists, so it falls back to the settings Hive box.
/// The PIN is deliberately kept OUT of `settingsProvider` state so it can never
/// leak into exports or UI; only the `appLockPinSet` flag lives there.
///
/// Failed attempts and the lockout deadline are persisted next to the PIN, so
/// killing/restarting the app does not reset the limiter.
class AppLockPinStore {
  AppLockPinStore._();
  static final AppLockPinStore instance = AppLockPinStore._();

  static const String _secureKey = 'app_lock_pin';
  static const String _webBoxKey = 'appLockPin';
  static const String _failedKey = 'app_lock_pin_failed_attempts';
  static const String _lockedUntilKey = 'app_lock_pin_locked_until_ms';
  static const String _settingsBoxName = 'settingsBox';
  static const int pinLength = 4;

  /// Wrong attempts allowed before the first lockout.
  static const int freeAttempts = 5;

  /// Longest single lockout. Also used to clamp deadlines when the device
  /// clock is moved backwards, so a user can never be locked out forever.
  static const Duration maxLockout = Duration(minutes: 30);

  static final RegExp _pinPattern = RegExp(r'^\d{4}$');

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static bool isValidFormat(String pin) => _pinPattern.hasMatch(pin);

  /// Escalating lockout after the [failures]-th consecutive wrong PIN.
  /// 1–4 → none, 5 → 30 s, 6 → 1 min, 7 → 5 min, 8 → 15 min, 9+ → 30 min.
  /// With 4-digit PINs (10 000 combinations) this pushes an exhaustive guess
  /// to many months of continuous effort.
  @visibleForTesting
  static Duration lockoutAfterFailures(int failures) {
    if (failures < freeAttempts) return Duration.zero;
    switch (failures - freeAttempts) {
      case 0:
        return const Duration(seconds: 30);
      case 1:
        return const Duration(minutes: 1);
      case 2:
        return const Duration(minutes: 5);
      case 3:
        return const Duration(minutes: 15);
      default:
        return maxLockout;
    }
  }

  Future<Box> _settingsBox() async {
    if (Hive.isBoxOpen(_settingsBoxName)) return Hive.box(_settingsBoxName);
    return Hive.openBox(_settingsBoxName);
  }

  // ── Low-level key/value (secure store, or settings box on web) ──────────

  Future<String?> _get(String secureKey, String webKey) async {
    if (kIsWeb) return (await _settingsBox()).get(webKey)?.toString();
    return _secureStorage.read(key: secureKey);
  }

  Future<void> _set(String secureKey, String webKey, String value) async {
    if (kIsWeb) {
      await (await _settingsBox()).put(webKey, value);
    } else {
      await _secureStorage.write(key: secureKey, value: value);
    }
  }

  Future<void> _remove(String secureKey, String webKey) async {
    if (kIsWeb) {
      await (await _settingsBox()).delete(webKey);
    } else {
      await _secureStorage.delete(key: secureKey);
    }
  }

  // ── PIN ──────────────────────────────────────────────────────────────────

  Future<String?> read() async {
    final value = await _get(_secureKey, _webBoxKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<bool> hasPin() async => (await read()) != null;

  /// Raw comparison without rate limiting. Prefer [verifyWithLimit] for any
  /// user-entered PIN.
  @visibleForTesting
  Future<bool> verify(String candidate) async {
    final stored = await read();
    return stored != null && stored == candidate;
  }

  Future<void> write(String pin) async {
    if (!isValidFormat(pin)) {
      throw ArgumentError('PIN must be exactly $pinLength digits');
    }
    await _set(_secureKey, _webBoxKey, pin);
    await resetAttempts();
  }

  Future<void> delete() async {
    await _remove(_secureKey, _webBoxKey);
    await resetAttempts();
  }

  // ── Attempt limiter ──────────────────────────────────────────────────────

  Future<int> _failedAttempts() async =>
      int.tryParse(await _get(_failedKey, _failedKey) ?? '') ?? 0;

  /// Remaining lockout, or [Duration.zero] when the PIN may be tried.
  Future<Duration> lockoutRemaining({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final untilMs =
        int.tryParse(await _get(_lockedUntilKey, _lockedUntilKey) ?? '');
    if (untilMs == null) return Duration.zero;
    var remaining =
        DateTime.fromMillisecondsSinceEpoch(untilMs).difference(current);
    if (remaining <= Duration.zero) return Duration.zero;
    // Clock moved backwards: never exceed the maximum single lockout.
    if (remaining > maxLockout) remaining = maxLockout;
    return remaining;
  }

  /// Clears the failure counter (after a correct PIN or biometric unlock).
  Future<void> resetAttempts() async {
    await _remove(_failedKey, _failedKey);
    await _remove(_lockedUntilKey, _lockedUntilKey);
  }

  /// Checks [candidate] subject to the attempt limiter. While locked out the
  /// candidate is not compared at all, so guesses during a lockout are free
  /// of information and do not extend the counter.
  Future<PinVerifyResult> verifyWithLimit(
    String candidate, {
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final stored = await read();
    if (stored == null) return const PinVerifyResult(PinVerifyStatus.noPin);

    final remaining = await lockoutRemaining(now: current);
    if (remaining > Duration.zero) {
      return PinVerifyResult(PinVerifyStatus.lockedOut, retryAfter: remaining);
    }

    if (candidate == stored) {
      await resetAttempts();
      return const PinVerifyResult(PinVerifyStatus.success);
    }

    final failures = await _failedAttempts() + 1;
    await _set(_failedKey, _failedKey, failures.toString());
    final lockout = lockoutAfterFailures(failures);
    if (lockout > Duration.zero) {
      await _set(
        _lockedUntilKey,
        _lockedUntilKey,
        current.add(lockout).millisecondsSinceEpoch.toString(),
      );
      return PinVerifyResult(
        PinVerifyStatus.lockedOut,
        retryAfter: lockout,
        attemptsBeforeLockout: 0,
      );
    }
    return PinVerifyResult(
      PinVerifyStatus.incorrect,
      attemptsBeforeLockout: freeAttempts - failures,
    );
  }
}
