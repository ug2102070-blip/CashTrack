import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:cashtrack/data/models/account_model.dart';
import 'package:cashtrack/data/models/transaction_model.dart';
import 'package:cashtrack/data/repositories/account_repository.dart';
import 'package:cashtrack/data/repositories/transaction_repository.dart';
import 'package:cashtrack/presentation/providers/app_providers.dart';

import 'hive_test_setup.dart';

void main() {
  setUpAll(() async {
    await initializeCashtrackRepositoriesForWidgetTest();
  });

  setUp(() async {
    await Hive.box('transactions').clear();
    await Hive.box('accounts').clear();
    await AccountRepository().init();
  });

  test('dashboard summary aggregates balance and recent transactions correctly',
      () async {
    await AccountRepository().addAccount(
      AccountModel(
        id: 'acc_custom',
        name: 'Savings',
        nameBn: 'Savings',
        type: AccountType.bank,
        balance: 3000,
        createdAt: DateTime(2026, 4, 25),
      ),
    );

    await TransactionRepository().addTransaction(
      TransactionModel(
        id: 'tx_old',
        type: TransactionType.expense,
        amount: 200,
        categoryId: 'cat_food',
        accountId: 'acc_cash',
        date: DateTime(2026, 4, 20, 8),
      ),
    );
    await TransactionRepository().addTransaction(
      TransactionModel(
        id: 'tx_new',
        type: TransactionType.income,
        amount: 1200,
        categoryId: 'cat_salary',
        accountId: 'acc_custom',
        date: DateTime(2026, 4, 25, 9),
      ),
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(accountsProvider.notifier).loadAccounts();
    container.read(transactionsProvider.notifier).loadTransactions();

    final summary = container.read(dashboardSummaryProvider);

    expect(summary.totalBalance, 3000);
    expect(summary.totalIncome, 1200);
    expect(summary.totalExpense, 200);
    expect(summary.recentTransactions.first.id, 'tx_new');
    expect(summary.recentTransactions.last.id, 'tx_old');
  });
}
