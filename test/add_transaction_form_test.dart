import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import 'package:cashtrack/data/repositories/account_repository.dart';
import 'package:cashtrack/data/repositories/category_repository.dart';
import 'package:cashtrack/data/repositories/transaction_repository.dart';
import 'package:cashtrack/presentation/providers/app_providers.dart';
import 'package:cashtrack/presentation/transactions/add_transaction_form.dart';

import 'hive_test_setup.dart';

void main() {
  setUpAll(() async {
    await initializeCashtrackRepositoriesForWidgetTest();
  });

  setUp(() async {
    if (Hive.isBoxOpen('transactions')) {
      await Hive.box('transactions').clear();
    }
    if (Hive.isBoxOpen('accounts')) {
      await Hive.box('accounts').clear();
    }
    if (Hive.isBoxOpen('categories')) {
      await Hive.box('categories').clear();
    }

    await CategoryRepository().init();
    await AccountRepository().init();
  });

  testWidgets(
    'AddTransactionForm saves expense via numpad and category/account pickers',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: '/add',
        routes: [
          GoRoute(
            path: '/add',
            builder: (context, state) => const Scaffold(
              body: AddTransactionForm(),
            ),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Text('Home'),
            ),
          ),
        ],
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(accountsProvider.notifier).loadAccounts();
      container.read(categoriesProvider.notifier).loadCategories();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            supportedLocales: const [Locale('en'), Locale('bn', 'BD')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('New Transaction'), findsOneWidget);

      // Enter amount via numpad
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('0'));
      await tester.pump();

      // --- Category picker ---
      // Open the category bottom sheet by tapping the "Select" placeholder.
      await tester.tap(find.text('Select').first);
      await tester.pumpAndSettle();

      // The picker is a scrollable ListView inside a bottom sheet.
      // "Food" may not be visible initially (sorted alphabetically among 30+
      // expense categories). Scroll the picker list until "Food" is visible.
      await tester.scrollUntilVisible(
        find.text('Food'),
        200, // scroll delta per step
        scrollable: find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // --- Save transaction ---
      await tester.tap(find.text('Save Transaction'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final txs = TransactionRepository().getAllTransactions();
      expect(txs.length, 1);
      expect(txs.first.amount, 10);
      expect(txs.first.categoryId, 'cat_food');
      expect(txs.first.accountId, isNotEmpty);
      // Any default account is valid — multiple accounts have isDefault: true.
      expect(
        ['acc_cash', 'acc_bkash', 'acc_nagad', 'acc_rocket', 'acc_upay', 'acc_online'],
        contains(txs.first.accountId),
      );
    },
  );
}
