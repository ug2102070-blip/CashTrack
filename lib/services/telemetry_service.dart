import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/logger.dart';

/// Privacy-safe operational telemetry. Never pass transaction content, account
/// identifiers, notification text, email addresses, or provider responses here.
class TelemetryService {
  TelemetryService._();

  /// Initialize Crashlytics collection settings safely
  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      // In debug mode, collection can be disabled to avoid polluting crash dashboards
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
      AppLogger.i('Crashlytics initialized (collectionEnabled=${!kDebugMode})');
    } catch (e) {
      AppLogger.w('Crashlytics init skipped: $e');
    }
  }

  /// Sets the current user identifier (hashed or UID) for crash correlation
  static Future<void> setUserId(String userId) async {
    if (kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    } catch (_) {
      // Telemetry errors must never crash the application
    }
  }

  /// Logs a privacy-safe breadcrumb to track user journey before a crash
  static Future<void> logBreadcrumb(String message) async {
    AppLogger.d('[Breadcrumb] $message');
    if (kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.log(message);
    } catch (_) {
      // Telemetry errors must never crash the application
    }
  }

  /// Records a Flutter framework error details instance
  static Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) async {
    AppLogger.e('FlutterError: ${details.exceptionAsString()}');
    if (kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.recordFlutterError(
        details,
        fatal: fatal,
      );
    } catch (_) {
      // Telemetry errors must never crash the application
    }
  }

  /// Records an operational failure or non-fatal exception
  static Future<void> recordFailure({
    required String operation,
    required Object error,
    StackTrace? stackTrace,
    bool fatal = false,
  }) async {
    final reason = _reasonCode(error);
    AppLogger.e('operation=$operation reason=$reason error=$error');
    if (kIsWeb) return;

    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: fatal,
        reason: operation,
        information: <Object>['reason=$reason', 'operation=$operation'],
      );
    } catch (_) {
      // Error reporting must never trigger another application failure.
    }
  }

  static String _reasonCode(Object error) {
    final raw = error.runtimeType.toString().toLowerCase();
    if (raw.contains('socket') || raw.contains('network') || raw.contains('http')) return 'network';
    if (raw.contains('permission')) return 'permission';
    if (raw.contains('timeout')) return 'timeout';
    if (raw.contains('firebase') || raw.contains('firestore')) return 'firebase';
    if (raw.contains('hive') || raw.contains('storage')) return 'storage';
    if (raw.contains('format') || raw.contains('parse')) return 'parse';
    return 'unexpected';
  }
}
