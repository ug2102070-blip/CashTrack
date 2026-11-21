import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:cashtrack/presentation/providers/app_providers.dart';

import 'hive_test_setup.dart';

void main() {
  setUpAll(() async {
    await initializeHiveForTests();
  });

  setUp(() async {
    final box = await Hive.openBox('settingsBox');
    await box.clear();
  });

  test('SettingsNotifier persists dark mode and currency', () async {
    final notifier = SettingsNotifier();

    await notifier.toggleDarkMode(true);
    await notifier.updateCurrency('USD');

    expect(notifier.state['darkMode'], true);
    expect(notifier.state['currency'], 'USD');

    final box = Hive.box('settingsBox');
    expect(box.get('darkMode'), true);
    expect(box.get('currency'), 'USD');
  });

  test('SettingsNotifier loads persisted values from Hive', () async {
    final box = Hive.box('settingsBox');
    await box.put('darkMode', true);
    await box.put('currency', 'EUR');
    await box.put('accentColor', 0xFF123456);

    final notifier = SettingsNotifier();

    expect(notifier.state['darkMode'], true);
    expect(notifier.state['currency'], 'EUR');
    expect(notifier.state['accentColor'], 0xFF123456);
  });

  test('last cloud backup timestamp survives a restart', () async {
    const stamp = '2026-11-20T10:15:00.000Z';
    await SettingsNotifier().update('lastCloudBackupAt', stamp);

    // A fresh notifier simulates an app restart reading from Hive.
    final reloaded = SettingsNotifier();
    expect(reloaded.state['lastCloudBackupAt'], stamp);
  });

  test('security and preference toggles persist across restart', () async {
    final notifier = SettingsNotifier();
    await notifier.update('autoLockMinutes', 15);
    await notifier.update('appLockPinSet', true);
    await notifier.update('biometricLock', true);
    await notifier.update('screenshotProtection', true);
    await notifier.update('weeklyReport', true);
    await notifier.update('dailyReminderTime', '21:30');
    await notifier.updateLanguage('bn');
    await notifier.updateSmsMode('ask');

    final reloaded = SettingsNotifier();
    expect(reloaded.state['autoLockMinutes'], 15);
    expect(reloaded.state['appLockPinSet'], true);
    expect(reloaded.state['biometricLock'], true);
    expect(reloaded.state['screenshotProtection'], true);
    expect(reloaded.state['weeklyReport'], true);
    expect(reloaded.state['dailyReminderTime'], '21:30');
    expect(reloaded.state['language'], 'bn');
    expect(reloaded.state['smsMode'], 'ask');
  });

  test('raw PIN stored in the settings box never enters provider state',
      () async {
    // Web builds keep the PIN in settingsBox; it must not surface in state,
    // because state is what gets exported to JSON.
    await Hive.box('settingsBox').put('appLockPin', '1234');
    final notifier = SettingsNotifier();
    expect(notifier.state.containsKey('appLockPin'), isFalse);
  });
}
