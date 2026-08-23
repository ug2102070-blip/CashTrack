import 'package:flutter_test/flutter_test.dart';

import 'package:cashtrack/data/models/budget_model.dart';
import 'package:cashtrack/data/models/debt_model.dart';
import 'package:cashtrack/presentation/dashboard/dashboard_health_evaluator.dart';
import 'package:cashtrack/presentation/providers/app_providers.dart';

void main() {
  test('returns no-data guidance for an empty financial profile', () {
    final result = DashboardHealthEvaluator.evaluate(
      summary: DashboardSummary(
        totalBalance: 0,
        totalIncome: 0,
        totalExpense: 0,
        recentTransactions: const [],
      ),
      budgets: const [],
      debts: const [],
      transactions: const [],
    );

    expect(result.score, 0);
    expect(result.statusText, 'No Data');
  });

  test('penalizes overspending and unpaid borrowed debt', () {
    final result = DashboardHealthEvaluator.evaluate(
      summary: DashboardSummary(
        totalBalance: 100,
        totalIncome: 1000,
        totalExpense: 1300,
        recentTransactions: const [],
      ),
      budgets: [
        BudgetModel(
          id: 'food',
          categoryId: 'food',
          amount: 100,
          month: DateTime(2026, 8),
        ),
      ],
      debts: [
        DebtModel(
          id: 'debt',
          personName: 'Test',
          amount: 500,
          paidAmount: 0,
          type: DebtType.borrowed,
          dueDate: DateTime(2026, 9),
        ),
      ],
      transactions: const [],
    );

    expect(result.score, lessThan(50));
    expect(result.statusText, 'Critical status');
  });
}
