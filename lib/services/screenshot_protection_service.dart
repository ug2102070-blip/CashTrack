import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenshotProtectionService {
  ScreenshotProtectionService._();

  static final ScreenshotProtectionService instance =
      ScreenshotProtectionService._();

  static const MethodChannel _channel =
      MethodChannel('cashtrack/security');

  Future<bool> apply({required bool enabled}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>(
        'setScreenshotProtection',
        {'enabled': enabled},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
