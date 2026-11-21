import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cashtrack/core/l10n/app_l10n.dart';

/// `AppL10n.t` returns the key itself when it is missing, so a typo silently
/// ships the raw key to users. This scans the security-sensitive screens for
/// literal `t('key')` calls and asserts each key has English and Bangla text.
void main() {
  const files = [
    'lib/presentation/settings/settings_screen.dart',
    'lib/presentation/security/app_lock_gate.dart',
  ];
  final keyPattern = RegExp(r"""\.t\(\s*'([a-z0-9_]+)'""");
  // Conditional keys: `t(flag ? 'x_on' : 'x_off')`.
  final ternaryPattern =
      RegExp(r"""\.t\(\s*\w+\s*\?\s*'([a-z0-9_]+)'\s*:\s*'([a-z0-9_]+)'""");

  for (final path in files) {
    test('every l10n key in $path exists in en and bn', () {
      final source = File(path).readAsStringSync();
      final keys = <String>{
        for (final m in keyPattern.allMatches(source)) m.group(1)!,
        for (final m in ternaryPattern.allMatches(source)) ...[
          m.group(1)!,
          m.group(2)!,
        ],
      };
      expect(keys, isNotEmpty);

      final en = AppL10n(const Locale('en'));
      final bn = AppL10n(const Locale('bn'));
      final missing = [
        for (final k in keys)
          if (en.t(k) == k || bn.t(k) == k) k,
      ]..sort();
      expect(missing, isEmpty, reason: 'Missing translations: $missing');
    });
  }
}
