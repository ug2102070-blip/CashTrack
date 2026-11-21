import 'package:flutter_test/flutter_test.dart';
import 'package:cashtrack/data/models/transaction_model.dart';
import 'package:cashtrack/presentation/providers/app_providers.dart';

void main() {
  group('MonthlyAnalytics Model & Calculations', () {
    test('calculates netSavings, savingsRate, and MoM changes accurately', () {
      final now = DateTime(2026, 11, 1);
      final txList = [
        TransactionModel(
          id: 'tx_1',
          type: TransactionType.income,
          amount: 5000000, // 50,000.00 BDT
          categoryId: 'cat_salary',
          accountId: 'acc_bank',
          date: DateTime(2026, 11, 2),
        ),
        TransactionModel(
          id: 'tx_2',
          type: TransactionType.expense,
          amount: 2000000, // 20,000.00 BDT
          categoryId: 'cat_food',
          accountId: 'acc_bkash',
          date: DateTime(2026, 11, 5),
        ),
        TransactionModel(
          id: 'tx_3',
          type: TransactionType.expense,
          amount: 1000000, // 10,000.00 BDT
          categoryId: 'cat_rent',
          accountId: 'acc_bank',
          date: DateTime(2026, 11, 10),
        ),
        TransactionModel(
          id: 'tx_deleted',
          type: TransactionType.expense,
          amount: 500000,
          categoryId: 'cat_food',
          accountId: 'acc_bkash',
          date: DateTime(2026, 11, 12),
          isDeleted: true,
        ),
      ];

      final analytics = MonthlyAnalytics(
        month: now,
        transactions: txList,
        totalIncome: 5000000,
        totalExpense: 3000000,
        previousIncome: 4000000,
        previousExpense: 4000000, // Previous was 40,000, current is 30,000 (-25%)
      );

      expect(analytics.netSavings, 2000000);
      expect(analytics.savingsRate, 40.0); // (20,000 / 50,000) * 100 = 40%

      // MoM: (3,000,000 - 4,000,000) / 4,000,000 * 100 = -25.0%
      expect(analytics.expenseChangePercentage, -25.0);
      expect(analytics.incomeChangePercentage, 25.0);

      // Category breakdown (excludes deleted)
      final expenseBreakdown =
          analytics.getCategoryBreakdown(TransactionType.expense);
      expect(expenseBreakdown['cat_food'], 2000000);
      expect(expenseBreakdown['cat_rent'], 1000000);
      expect(expenseBreakdown.containsKey('tx_deleted'), false);

      // Account breakdown (excludes deleted)
      final accountBreakdown =
          analytics.getAccountBreakdown(TransactionType.expense);
      expect(accountBreakdown['acc_bkash'], 2000000);
      expect(accountBreakdown['acc_bank'], 1000000);
    });

    test('handles zero previous month gracefully', () {
      final analytics = MonthlyAnalytics(
        month: DateTime(2026, 11, 1),
        transactions: [],
        totalIncome: 10000,
        totalExpense: 5000,
        previousIncome: 0,
        previousExpense: 0,
      );

      expect(analytics.expenseChangePercentage, isNull);
      expect(analytics.incomeChangePercentage, isNull);
    });
  });
}
