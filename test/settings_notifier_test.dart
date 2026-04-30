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
}
