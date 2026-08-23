import 'package:flutter/foundation.dart';

class AppLogger {
  static String _safe(String message) {
    // Prevent common PII from appearing in release logs. Callers must still
    // avoid logging financial descriptions or provider responses.
    return message
        .replaceAll(RegExp(r'\b\d{10,16}\b'), '[redacted-number]')
        .replaceAll(
            RegExp(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}'), '[redacted-email]');
  }

  static void d(String message) {
    if (kDebugMode) {
      debugPrint(_safe(message));
    }
  }

  static void i(String message) {
    if (kDebugMode) {
      debugPrint(_safe(message));
    }
  }

  static void w(String message) {
    if (kDebugMode) {
      debugPrint('WARN: ${_safe(message)}');
    }
  }

  static void e(String message) {
    if (kDebugMode) {
      debugPrint('ERROR: ${_safe(message)}');
    }
  }
}
