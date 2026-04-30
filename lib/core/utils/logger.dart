import 'package:flutter/foundation.dart';

class AppLogger {
  static void d(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void i(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void w(String message) {
    if (kDebugMode) {
      debugPrint('WARN: $message');
    }
  }

  static void e(String message) {
    if (kDebugMode) {
      debugPrint('ERROR: $message');
    }
  }
}
