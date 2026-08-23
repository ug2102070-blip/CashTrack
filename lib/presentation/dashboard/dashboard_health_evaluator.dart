import '../../data/models/budget_model.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/transaction_model.dart';
import '../providers/app_providers.dart';

class DashboardHealth {
  const DashboardHealth({
    required this.score,
    required this.statusText,
    required this.detailText,
  });

  final double score;
  final String statusText;
  final String detailText;
}

/// Pure dashboard business logic, deliberately separated from widgets so it
/// can be independently tested and localized in a later presentation pass.
class DashboardHealthEvaluator {
  const DashboardHealthEvaluator._();

  static DashboardHealth evaluate({
    required DashboardSummary summary,
    required List<BudgetModel> budgets,
    required List<DebtModel> debts,
    required List<TransactionModel> transactions,
  }) {
    final hasData = summary.totalIncome > 0 ||
        summary.totalExpense > 0 ||
        budgets.isNotEmpty ||
        debts.isNotEmpty;
    if (!hasData) {
      return const DashboardHealth(
        score: 0,
        statusText: 'No Data',
        detailText: 'Add your income, expenses, and budgets to get started.',
      );
    }

    var score = 80.0;
    if (summary.totalIncome > 0) {
      final savingsRate = (summary.totalIncome - summary.totalExpense) /
          summary.totalIncome *
          100;
      if (savingsRate >= 30) {
        score += 15;
      } else if (savingsRate >= 10) {
        score += 5;
      } else if (savingsRate < 0) {
        score -= 25;
      } else {
        score -= 5;
      }
    } else if (summary.totalExpense > 0) {
      score -= 30;
    }

    final overspent =
        budgets.where((budget) => budget.getSpent(transactions) > budget.amount).length;
    score -= overspent * 8;
    final borrowedUnpaid = debts
        .where((debt) => debt.type == DebtType.borrowed && !debt.isSettled)
        .fold<double>(
            0,
            (sum, debt) =>
                sum +
                (debt.amount - debt.paidAmount).clamp(0, double.infinity));
    if (borrowedUnpaid > 0) {
      if (summary.totalBalance <= 0) {
        score -= 20;
      } else {
        final ratio = borrowedUnpaid / summary.totalBalance;
        score -= ratio > 1
            ? 20
            : ratio > .5
                ? 12
                : 5;
      }
    }
    score = score.clamp(0, 100);

    final netNegative = summary.totalIncome > 0 && summary.netSavings < 0;
    final hasBorrowedDebt = debts.any(
      (debt) => debt.type == DebtType.borrowed && !debt.isSettled,
    );
    if (score >= 85) {
      return DashboardHealth(
        score: score,
        statusText: 'Excellent status',
        detailText:
            'Your savings rate is high, budgets are respected, and debts are well-managed. Great work!',
      );
    }
    if (score >= 70) {
      return DashboardHealth(
        score: score,
        statusText: 'Healthy status',
        detailText: overspent > 0
            ? 'Good overall, but you have exceeded some budgets. Monitor categories closely to improve your score.'
            : 'Good balance. Consider increasing your monthly savings rate to reach an excellent score.',
      );
    }
    if (score >= 50) {
      return DashboardHealth(
        score: score,
        statusText: 'Fair status',
        detailText: netNegative
            ? 'You spent more than you earned this month. Reduce discretionary spending immediately.'
            : hasBorrowedDebt
                ? 'Outstanding borrowed debts are holding back your score. Focus on paying down your debts.'
                : 'You have fair financial habits. Focus on strict budget adherence and increasing savings.',
      );
    }
    return DashboardHealth(
      score: score,
      statusText: 'Critical status',
      detailText: netNegative
          ? 'Critical: Overspending is severe. Focus on reducing all non-essential expenses and clearing debts.'
          : 'Critical status. Please set budgets for your main spending categories and reduce expenses.',
    );
  }
}
