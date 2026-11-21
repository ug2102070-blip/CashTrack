import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:cashtrack/presentation/providers/app_providers.dart';
import 'package:cashtrack/presentation/settings/settings_screen.dart';
import 'package:cashtrack/services/app_lock_pin_store.dart';

import 'hive_test_setup.dart';

/// Real file I/O (Hive) started inside the fake-async test zone completes
/// only when real time passes AND the fake zone is pumped. Chained awaits
/// (secure-storage write → Hive put → snackbar) need several such cycles;
/// leaving one unfinished blocks the next test's Hive access.
Future<void> _drainAsync(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _pumpSettings(
    WidgetTester tester, ProviderContainer container) async {
  // Tall surface so every lazily-built sliver section is laid out.
  tester.view.physicalSize = const Size(1200, 9000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openPinDialog(WidgetTester tester) async {
  await tester.tap(find.text('App Lock PIN'));
  // _showPinDialog awaits secure storage before opening the dialog.
  await _drainAsync(tester);
  expect(find.byType(AlertDialog), findsOneWidget);
}

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await _drainAsync(tester);
}

/// Unmounts the screen and flushes pending I/O so nothing started in the fake
/// zone is left hanging for the next test.
Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await _drainAsync(tester);
}

Finder _field(String label) => find.widgetWithText(TextField, label);

/// Widget tests for the Settings → App Lock PIN flow.
void main() {
  setUpAll(() async {
    await initializeHiveForTests();
    // In-memory backend: file I/O futures never resolve deterministically
    // inside the widget-test fake-async zone, memory-backed ones do.
    if (Hive.isBoxOpen('settingsBox')) await Hive.box('settingsBox').close();
    await Hive.openBox('settingsBox', bytes: Uint8List(0));
  });

  late ProviderContainer container;

  Future<void> resetState({Map<String, String> secure = const {}}) async {
    FlutterSecureStorage.setMockInitialValues(Map.of(secure));
    await Hive.box('settingsBox').clear();
    if (secure.containsKey('app_lock_pin')) {
      await Hive.box('settingsBox').put('appLockPinSet', true);
    }
    container = ProviderContainer();
  }

  tearDown(() => container.dispose());

  group('without an existing PIN', () {
    setUp(() => resetState());

    testWidgets('setting a new PIN requires no current PIN and persists it',
        (tester) async {
      await _pumpSettings(tester, container);
      await _openPinDialog(tester);

      expect(_field('Current PIN'), findsNothing);
      await tester.enterText(_field('Enter PIN'), '2468');
      await tester.enterText(_field('Confirm PIN'), '2468');
      await _tapAndSettle(tester, find.text('Save'));

      expect(find.byType(AlertDialog), findsNothing);
      final stored = await tester.runAsync(AppLockPinStore.instance.read);
      expect(stored, '2468');
      expect(container.read(settingsProvider)['appLockPinSet'], true);
      await _finish(tester);
    });

    testWidgets('PIN fields reject non-digit input', (tester) async {
      await _pumpSettings(tester, container);
      await _openPinDialog(tester);

      await tester.enterText(_field('Enter PIN'), '1a2b3c4d5');
      final text =
          tester.widget<TextField>(_field('Enter PIN')).controller!.text;
      expect(text, '1234');
      await _finish(tester);
    });

    testWidgets(
        'mismatched confirmation shows an inline error and saves nothing',
        (tester) async {
      await _pumpSettings(tester, container);
      await _openPinDialog(tester);

      await tester.enterText(_field('Enter PIN'), '1111');
      await tester.enterText(_field('Confirm PIN'), '2222');
      await _tapAndSettle(tester, find.text('Save'));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(await tester.runAsync(AppLockPinStore.instance.hasPin), isFalse);
      await _finish(tester);
    });
  });

  group('with an existing PIN', () {
    setUp(() => resetState(secure: {'app_lock_pin': '1357'}));

    testWidgets('wrong current PIN blocks changing the PIN', (tester) async {
      await _pumpSettings(tester, container);
      await _openPinDialog(tester);

      await tester.enterText(_field('Current PIN'), '0000');
      await tester.enterText(_field('New PIN'), '2468');
      await tester.enterText(_field('Confirm PIN'), '2468');
      await _tapAndSettle(tester, find.text('Save'));

      expect(find.text('Current PIN is incorrect'), findsOneWidget);
      expect(
          await tester.runAsync(() => AppLockPinStore.instance.verify('1357')),
          isTrue);
      await _finish(tester);
    });

    testWidgets('wrong current PIN blocks removing the PIN', (tester) async {
      await _pumpSettings(tester, container);
      await _openPinDialog(tester);

      await tester.enterText(_field('Current PIN'), '9999');
      await _tapAndSettle(tester, find.text('Remove PIN'));

      expect(find.text('Current PIN is incorrect'), findsOneWidget);
      expect(await tester.runAsync(AppLockPinStore.instance.hasPin), isTrue);
      expect(container.read(settingsProvider)['appLockPinSet'], true);
      await _finish(tester);
    });

    testWidgets('repeated wrong current PINs trigger the shared lockout',
        (tester) async {
      await _pumpSettings(tester, container);
      await _openPinDialog(tester);

      for (var i = 0; i < AppLockPinStore.freeAttempts; i++) {
        await tester.enterText(_field('Current PIN'), '0000');
        await _tapAndSettle(tester, find.text('Remove PIN'));
      }
      expect(find.textContaining('Too many wrong attempts'), findsOneWidget);

      // Even the correct PIN is refused while locked out.
      await tester.enterText(_field('Current PIN'), '1357');
      await _tapAndSettle(tester, find.text('Remove PIN'));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(await tester.runAsync(AppLockPinStore.instance.hasPin), isTrue);
      await _finish(tester);
    });

    testWidgets('correct current PIN allows removing the PIN', (tester) async {
      await _pumpSettings(tester, container);
      await _openPinDialog(tester);

      await tester.enterText(_field('Current PIN'), '1357');
      await _tapAndSettle(tester, find.text('Remove PIN'));

      expect(find.byType(AlertDialog), findsNothing);
      expect(await tester.runAsync(AppLockPinStore.instance.hasPin), isFalse);
      expect(container.read(settingsProvider)['appLockPinSet'], false);
      await _finish(tester);
    });

    testWidgets('correct current PIN allows changing the PIN', (tester) async {
      await _pumpSettings(tester, container);
      await _openPinDialog(tester);

      await tester.enterText(_field('Current PIN'), '1357');
      await tester.enterText(_field('New PIN'), '8642');
      await tester.enterText(_field('Confirm PIN'), '8642');
      await _tapAndSettle(tester, find.text('Save'));

      expect(find.byType(AlertDialog), findsNothing);
      expect(
          await tester.runAsync(() => AppLockPinStore.instance.verify('8642')),
          isTrue);
      await _finish(tester);
    });
  });
}
