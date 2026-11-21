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

  String localizedStatus(bool isBangla) {
    if (!isBangla) return statusText;
    switch (statusText) {
      case 'No Data':
        return 'কোনো তথ্য নেই';
      case 'Excellent status':
        return 'চমৎকার আর্থিক অবস্থা';
      case 'Healthy status':
        return 'স্বাস্থ্যকর আর্থিক অবস্থা';
      case 'Fair status':
        return 'মোটামুটি আর্থিক অবস্থা';
      case 'Critical status':
        return 'সতর্কতামূলক অবস্থা';
      default:
        return statusText;
    }
  }

  String localizedDetail(bool isBangla) {
    if (!isBangla) return detailText;
    switch (statusText) {
      case 'No Data':
        return 'শুরু করতে আপনার আয়, ব্যয় এবং বাজেট যোগ করুন।';
      case 'Excellent status':
        return 'আপনার সঞ্চয়ের হার চমৎকার, বাজেট নিয়ন্ত্রণে রয়েছে এবং ঋণ যথাযথভাবে পরিচালিত হচ্ছে। দারুণ কাজ!';
      case 'Healthy status':
        if (detailText.contains('exceeded')) {
          return 'সার্বিকভাবে ভালো, তবে কিছু বাজেটের সীমা অতিক্রম করেছে। স্কোর উন্নত করতে ক্যাটাগরি খরচ পর্যবেক্ষণ করুন।';
        }
        return 'আর্থিক ভারসাম্য ভালো। সেরা স্কোর অর্জন করতে মাসিক সঞ্চয়ের হার আরও কিছুটা বাড়ানোর চেষ্টা করুন।';
      case 'Fair status':
        if (detailText.contains('spent more')) {
          return 'এই মাসে আপনার ব্যয় আয়ের চেয়ে বেশি হয়েছে। অবিলম্বে অপ্রয়োজনীয় খরচ কমান।';
        } else if (detailText.contains('Outstanding') || detailText.contains('debts')) {
          return 'বকেয়া ঋণ আপনার স্কোর কমিয়ে দিচ্ছে। ঋণ পরিশোধের দিকে নজর দিন।';
        }
        return 'আপনার আর্থিক অভ্যাস মাঝারি মানের। বাজেট মেনে চলা এবং সঞ্চয় বৃদ্ধির দিকে মনোনিবেশ করুন।';
      case 'Critical status':
        if (detailText.contains('severe')) {
          return 'সতর্কতা: অতিরিক্ত ব্যয় আশঙ্কাজনক। অপ্রয়োজনীয় ব্যয় বন্ধ করে ঋণ পরিশোধে অগ্রাধিকার দিন।';
        }
        return 'সতর্কতামূলক অবস্থা। মূল ব্যয়ের ক্যাটাগরিতে বাজেট সেট করুন এবং অপ্রয়োজনীয় ব্যয় কমিয়ে ফেলুন।';
      default:
        return detailText;
    }
  }
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
