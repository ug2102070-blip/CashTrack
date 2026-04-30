import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:cashtrack/data/models/transaction_model.dart';
import 'package:cashtrack/data/repositories/transaction_repository.dart';

import 'hive_test_setup.dart';

void main() {
  setUpAll(() async {
    await initializeHiveForTests();
    await TransactionRepository().init();
  });

  setUp(() async {
    await TransactionRepository().init();
    await Hive.box('transactions').clear();
  });

  test('adds, updates and calculates totals correctly', () async {
    final repo = TransactionRepository();

    final income = TransactionModel(
      id: 't_income',
      type: TransactionType.income,
      amount: 1000,
      categoryId: 'cat_salary',
      accountId: 'acc_cash',
      date: DateTime(2026, 2, 1),
    );

    final expense = TransactionModel(
      id: 't_expense',
      type: TransactionType.expense,
      amount: 250,
      categoryId: 'cat_food',
      accountId: 'acc_cash',
      date: DateTime(2026, 2, 2),
    );

    await repo.addTransaction(income);
    await repo.addTransaction(expense);

    expect(repo.getAllTransactions().length, 2);
    expect(repo.getTotalIncome(), 1000);
    expect(repo.getTotalExpense(), 250);

    await repo.updateTransaction(expense.copyWith(amount: 300));

    expect(repo.getTotalExpense(), 300);
  });

  test('soft delete excludes transactions from reads and totals', () async {
    final repo = TransactionRepository();

    final expense = TransactionModel(
      id: 't_delete',
      type: TransactionType.expense,
      amount: 400,
      categoryId: 'cat_food',
      accountId: 'acc_cash',
      date: DateTime(2026, 2, 3),
    );

    await repo.addTransaction(expense);
    expect(repo.getAllTransactions().length, 1);
    expect(repo.getTotalExpense(), 400);

    await repo.deleteTransaction(expense.id);

    expect(repo.getAllTransactions(), isEmpty);
    expect(repo.getTotalExpense(), 0);
  });
}
