// lib/presentation/dashboard/dashboard_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/amount_mask.dart';
import '../../core/l10n/app_l10n.dart';
import '../../data/models/account_model.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/split_expense_model.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/budget_model.dart';
import '../../services/auth_service.dart';
import '../providers/app_providers.dart';
import 'package:go_router/go_router.dart';
import 'widgets/expense_chart_dynamic.dart';
import 'widgets/transaction_list_dynamic.dart';
import 'widgets/premium_dashboard_widgets.dart';
import 'widgets/daily_budget_tracker_card.dart';
import 'dashboard_health_evaluator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/sms_service.dart';
import '../../services/subscription_detector_service.dart';
import '../../data/models/transaction_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animCtrl;
  bool _revealAmounts = false;
  ImageProvider? _profileImage;
  String? _profileImageCacheKey;
  late final PageController _leftPageController;
  late final PageController _rightPageController;
  int _leftPageIndex = 0;
  int _rightPageIndex = 0;
  bool _showAiInsight = true;

  // Pre-created animations to avoid creating new CurvedAnimation objects
  // on every build() call — which leaks InheritedWidget dependents and
  // causes '_dependents.isEmpty' assertion failures.
  static const List<int> _animDelays = [
    0,
    50,
    100,
    150,
    200,
    250,
    300,
    350,
    400,
    450,
    500,
    550
  ];
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _leftPageController = PageController();
    _rightPageController = PageController();
    _animCtrl = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this)
      ..forward();
    _fadeAnims = _animDelays.map((ms) {
      final s = (ms / 750).clamp(0.0, 1.0);
      final e = ((ms + 280) / 750).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _animCtrl, curve: Interval(s, e, curve: Curves.easeOutCubic));
    }).toList();
    _slideAnims = _animDelays.map((ms) {
      final s = (ms / 750).clamp(0.0, 1.0);
      final e = ((ms + 280) / 750).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _animCtrl,
              curve: Interval(s, e, curve: Curves.easeOutCubic)));
    }).toList();

    // Reload profile with current user's UID after auth redirect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(userProfileProvider.notifier).reloadProfile();
        _checkAndRequestNotificationPermission();
        _checkAndShowSmsPermissionDialog();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _leftPageController.dispose();
    _rightPageController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _scheduleRollover({required bool enabled}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref
          .read(budgetsProvider.notifier)
          .ensureMonthlyRollover(targetMonth: DateTime.now(), enabled: enabled);
    });
  }

  Widget _anim({required int index, required Widget child}) {
    final safeIndex = index.clamp(0, _fadeAnims.length - 1);
    return FadeTransition(
      opacity: _fadeAnims[safeIndex],
      child: SlideTransition(
        position: _slideAnims[safeIndex],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(dashboardSummaryProvider);
    final accounts = ref.watch(accountsProvider);
    final debts = ref.watch(debtsProvider);
    final settings = ref.watch(settingsProvider);
    final currency = (settings['currency'] as String?) ?? '\u09F3';
    final hideAmounts = settings['hideAmounts'] ?? false;
    final rolloverEnabled = settings['rolloverBudget'] ?? false;
    final effectiveHide = hideAmounts && !_revealAmounts;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    void toggleReveal() {
      if (!hideAmounts) return;
      setState(() => _revealAmounts = !_revealAmounts);
    }

    final budgets =
        ref.watch(budgetsProvider.notifier).getBudgetsForCurrentMonth();
    _scheduleRollover(enabled: rolloverEnabled);
    final allTransactions = ref.watch(transactionsProvider);
    final alertCount = _alertCount(summary, budgets, debts, allTransactions);

    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    final profile = ref.watch(userProfileProvider);
    final fullName = (profile['fullName'] ?? '').trim();

    // Calculate this month's stats
    final savingsAmount = (summary.totalIncome - summary.totalExpense)
        .clamp(0.0, double.infinity);
    final savingsRate = summary.totalIncome > 0
        ? (savingsAmount / summary.totalIncome * 100)
        : 0.0;

    // Budget stats
    final totalBudget = budgets.fold<double>(0, (sum, b) => sum + b.amount);
    final totalBudgetSpent =
        budgets.fold<double>(0, (sum, b) => sum + b.getSpent(allTransactions));
    final remainingBudget =
        (totalBudget - totalBudgetSpent).clamp(0.0, double.infinity);
    final budgetProgress =
        totalBudget > 0 ? (totalBudgetSpent / totalBudget) : 0.0;

    final categories = ref.watch(categoriesProvider);
    final goals = ref.watch(goalsProvider);

    final health = DashboardHealthEvaluator.evaluate(
      summary: summary,
      budgets: budgets,
      debts: debts,
      transactions: allTransactions,
    );
    final healthScore = health.score;
    final healthTrendText = health.localizedStatus(isBangla);
    final healthDetailText = health.localizedDetail(isBangla);

    // 2. Generate dynamic AI Insights
    String aiInsightText = isBangla
        ? 'এখানে আপনার ব্যয়ের ধারা বিশ্লেষণ করা হবে। অন্তর্দৃষ্টি পেতে কয়েকটি লেনদেন যোগ করুন!'
        : 'I will analyze your spending patterns here. Try adding some transactions to get your first insight!';
    if (allTransactions.isNotEmpty) {
      final categoryMap = {
        for (final c in categories)
          c.id: isBangla && c.nameBn.isNotEmpty ? c.nameBn : c.name
      };

      // Budget overrun check
      BudgetModel? worstOverrun;
      int maxOverrun = 0;
      for (final b in budgets) {
        final spent = b.getSpent(allTransactions);
        if (spent > b.amount) {
          final overrun = spent - b.amount;
          if (overrun > maxOverrun) {
            maxOverrun = overrun;
            worstOverrun = b;
          }
        }
      }

      if (worstOverrun != null) {
        final catName = categoryMap[worstOverrun.categoryId] ??
            (isBangla ? 'এই ক্যাটাগরি' : 'this category');
        final formattedOverrun = formatAmount(currency, maxOverrun);
        aiInsightText = isBangla
            ? '"$catName" ক্যাটাগরিতে খরচ আপনার বাজেটের চেয়ে $formattedOverrun বেশি হয়েছে। এই মাসে "$catName" খরচ সীমিত রাখুন।'
            : 'Your spending in "$catName" has exceeded your budget by $formattedOverrun. Consider limiting purchases in "$catName" for the rest of the month.';
      } else {
        // High spending category check
        final recentExpenses = allTransactions
            .where((t) => t.type == TransactionType.expense && !t.isDeleted)
            .toList();
        if (recentExpenses.isNotEmpty) {
          final Map<String, double> categorySums = {};
          double totalRecentExpense = 0;
          for (final tx in recentExpenses) {
            categorySums[tx.categoryId] =
                (categorySums[tx.categoryId] ?? 0) + tx.amount;
            totalRecentExpense += tx.amount;
          }

          String? highestCatId;
          double highestCatSum = 0;
          categorySums.forEach((catId, sum) {
            if (sum > highestCatSum) {
              highestCatSum = sum;
              highestCatId = catId;
            }
          });

          if (highestCatId != null && totalRecentExpense > 0) {
            final ratio = (highestCatSum / totalRecentExpense) * 100;
            final catName = categoryMap[highestCatId] ??
                (isBangla ? 'বিবিধ' : 'Miscellaneous');
            final formattedHighest = formatAmount(currency, highestCatSum);
            if (ratio > 30) {
              aiInsightText = isBangla
                  ? '"$catName" আপনার মোট খরচের ${ratio.toStringAsFixed(0)}% ($formattedHighest)। সাশ্রয়ী বিকল্প খোঁজা আপনাকে সঞ্চয়ে সাহায্য করবে।'
                  : '"$catName" accounts for ${ratio.toStringAsFixed(0)}% of your total expenses ($formattedHighest). Finding cheaper alternatives or buying in bulk could help you save.';
            } else if (summary.totalIncome > 0) {
              final sRate = ((summary.totalIncome - summary.totalExpense) /
                      summary.totalIncome) *
                  100;
              if (sRate > 20) {
                aiInsightText = isBangla
                    ? 'দারুণ! আপনার সঞ্চয়ের হার এই মাসে ${sRate.toStringAsFixed(0)}%। জরুরি তহবিল গঠনে এটি বজায় রাখুন।'
                    : 'Amazing! Your savings rate is at ${sRate.toStringAsFixed(0)}% this month. Keep it up to build your wealth/emergency fund faster.';
              } else if (sRate >= 0) {
                aiInsightText = isBangla
                    ? 'আপনি বর্তমানে আয়ের ${sRate.toStringAsFixed(0)}% সঞ্চয় করছেন। নিয়মিত সঞ্চয়ের অভ্যাস বজায় রাখুন।'
                    : 'You are currently saving ${sRate.toStringAsFixed(0)}% of your income. Try automating a portion of your savings to build consistent habits.';
              } else {
                final overSpentAmt = formatAmount(
                    currency, summary.totalExpense - summary.totalIncome);
                aiInsightText = isBangla
                    ? 'আপনার ব্যয় আয়ের চেয়ে $overSpentAmt বেশি। অপ্রয়োজনীয় ব্যয় ও সাবস্ক্রিপশন কমানোর চেষ্টা করুন।'
                    : 'Your expenses are higher than your income by $overSpentAmt. Let\'s identify non-essential subscriptions or lifestyle costs to cut back.';
              }
            } else {
              aiInsightText = isBangla
                  ? 'লেনদেন ট্র্যাকিং চমৎকার চলছে! সম্পূর্ণ ড্যাশবোর্ড পেতে খাবার, ইউটিলিটি ইত্যাদিতে বাজেট সেট করুন।'
                  : 'Tracking looks good so far! Try setting budgets for categories like Food, Utilities, and Transport to build a complete dashboard.';
            }
          }
        }
      }
    }

    // 3. Compute dynamic Weekly Spending Streak
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentMonday = today.subtract(Duration(days: now.weekday - 1));

    final dailyBudgetLimit = totalBudget > 0 ? (totalBudget / 30.0) : 100000.0;
    final List<bool> dailyStatus = List.generate(7, (index) {
      final dayDate = currentMonday.add(Duration(days: index));
      if (dayDate.isAfter(today)) {
        return false;
      }
      final dayExpense = allTransactions.where((t) {
        if (t.type != TransactionType.expense || t.isDeleted) return false;
        final txDay = DateTime(t.date.year, t.date.month, t.date.day);
        return txDay.isAtSameMomentAs(dayDate);
      }).fold<int>(0, (sum, t) => sum + t.amount);
      return dayExpense <= dailyBudgetLimit;
    });
    final streakDays = dailyStatus.where((status) => status).length;

    // 4. Retrieve and sort real upcoming bills
    final List<UpcomingBillItem> upcomingBills = [];
    final todayNormalized = DateTime(now.year, now.month, now.day);
    final thirtyDaysAhead = todayNormalized.add(const Duration(days: 30));

    DateTime advanceDate(DateTime date, RecurringType type, int anchorDay) {
      switch (type) {
        case RecurringType.daily:
          return date.add(const Duration(days: 1));
        case RecurringType.weekly:
          return date.add(const Duration(days: 7));
        case RecurringType.monthly:
          final nextMonth = DateTime(date.year, date.month + 1, 1);
          final maxDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
          final safeDay = anchorDay <= maxDay ? anchorDay : maxDay;
          return DateTime(nextMonth.year, nextMonth.month, safeDay);
        case RecurringType.yearly:
          final nextYear = DateTime(date.year + 1, date.month, 1);
          final maxDay = DateTime(nextYear.year, nextYear.month + 1, 0).day;
          final safeDay = anchorDay <= maxDay ? anchorDay : maxDay;
          return DateTime(nextYear.year, nextYear.month, safeDay);
      }
    }

    final recurringTxs = allTransactions.where(
        (t) => t.isRecurring && t.recurringType != null && !t.isDeleted);
    for (final tx in recurringTxs) {
      var currentOccur = DateTime(tx.date.year, tx.date.month, tx.date.day);
      while (currentOccur.isBefore(todayNormalized)) {
        currentOccur =
            advanceDate(currentOccur, tx.recurringType!, tx.date.day);
      }
      if (currentOccur.isBefore(thirtyDaysAhead) ||
          currentOccur.isAtSameMomentAs(thirtyDaysAhead)) {
        final diffDays = currentOccur.difference(todayNormalized).inDays;
        String dueMsg = '';
        Color bColor = AppColors.primary;
        if (diffDays == 0) {
          dueMsg = isBangla ? 'আজ প্রদেয়' : 'Due today';
          bColor = AppColors.error;
        } else if (diffDays == 1) {
          dueMsg = isBangla ? 'আগামীকাল প্রদেয়' : 'Due tomorrow';
          bColor = AppColors.error;
        } else if (diffDays <= 3) {
          dueMsg = isBangla ? '$diffDays দিনের মধ্যে প্রদেয়' : 'Due in $diffDays days';
          bColor = AppColors.warning;
        } else {
          dueMsg = isBangla ? '$diffDays দিনের মধ্যে প্রদেয়' : 'Due in $diffDays days';
          bColor = AppColors.success;
        }

        final categoryMap = {
          for (final c in categories)
            c.id: isBangla && c.nameBn.isNotEmpty ? c.nameBn : c.name
        };
        final nameLabel = tx.note?.isNotEmpty == true
            ? tx.note!
            : (categoryMap[tx.categoryId] ?? (isBangla ? 'নিয়মিত বিল' : 'Recurring Bill'));

        upcomingBills.add(UpcomingBillItem(
          name: nameLabel,
          amount: formatAmount(currency, tx.amount),
          dueDate: dueMsg,
          color: bColor,
        ));
      }
    }

    final detectedSubs =
        SubscriptionDetectorService().detectSubscriptions(allTransactions);
    for (final sub in detectedSubs) {
      final alreadyAdded = upcomingBills
          .any((b) => b.name.toLowerCase() == sub.merchantName.toLowerCase());
      if (alreadyAdded) continue;

      final nextDate = DateTime(sub.nextExpectedDate.year,
          sub.nextExpectedDate.month, sub.nextExpectedDate.day);
      if (nextDate
              .isAfter(todayNormalized.subtract(const Duration(days: 1))) &&
          nextDate.isBefore(thirtyDaysAhead.add(const Duration(days: 1)))) {
        final diffDays = nextDate.difference(todayNormalized).inDays;
        String dueMsg = '';
        Color bColor = AppColors.primary;
        if (diffDays == 0) {
          dueMsg = isBangla ? 'আজ প্রদেয়' : 'Due today';
          bColor = AppColors.error;
        } else if (diffDays == 1) {
          dueMsg = isBangla ? 'আগামীকাল প্রদেয়' : 'Due tomorrow';
          bColor = AppColors.error;
        } else if (diffDays <= 3) {
          dueMsg = isBangla ? '$diffDays দিনের মধ্যে প্রদেয়' : 'Due in $diffDays days';
          bColor = AppColors.warning;
        } else {
          dueMsg = isBangla ? '$diffDays দিনের মধ্যে প্রদেয়' : 'Due in $diffDays days';
          bColor = AppColors.success;
        }

        upcomingBills.add(UpcomingBillItem(
          name: sub.merchantName,
          amount: formatAmount(currency, sub.amount),
          dueDate: dueMsg,
          color: bColor,
        ));
      }
    }

    int getDays(String msg) {
      if (msg.contains('today') || msg.contains('আজ')) return 0;
      if (msg.contains('tomorrow') || msg.contains('আগামীকাল')) return 1;
      final reg = RegExp(r'\d+');
      final match = reg.firstMatch(msg);
      if (match != null) {
        return int.parse(match.group(0)!);
      }
      return 99;
    }

    upcomingBills
        .sort((a, b) => getDays(a.dueDate).compareTo(getDays(b.dueDate)));

    // 5. Compute real spending intensity heatmap data
    final startMonday = currentMonday.subtract(const Duration(days: 21));
    double maxDailySpend = 0.0;
    final List<double> dailySpends = List.generate(28, (index) {
      final dayDate = startMonday.add(Duration(days: index));
      final dayExpense = allTransactions.where((t) {
        if (t.type != TransactionType.expense || t.isDeleted) return false;
        final txDay = DateTime(t.date.year, t.date.month, t.date.day);
        return txDay.isAtSameMomentAs(dayDate);
      }).fold<double>(0, (sum, t) => sum + t.amount);

      if (dayExpense > maxDailySpend) {
        maxDailySpend = dayExpense;
      }
      return dayExpense;
    });

    final List<int> heatmapData = dailySpends.map((spend) {
      if (spend == 0) return 0;
      if (maxDailySpend == 0) return 0;
      final ratio = spend / maxDailySpend;
      if (ratio <= 0.33) return 1;
      if (ratio <= 0.66) return 2;
      return 3;
    }).toList();

    // 6. Generate dynamic Smart Recommendations
    final List<SmartRecommendationItem> recommendations = [];

    if (budgets.isEmpty) {
      recommendations.add(SmartRecommendationItem(
        icon: Icons.pie_chart_rounded,
        title: isBangla ? 'মাসিক বাজেট তৈরি করুন' : 'Create a monthly budget',
        desc: isBangla
            ? 'এই মাসের জন্য কোনো বাজেট সেট করা হয়নি। খরচ নিয়ন্ত্রণে বাজেট সীমা তৈরি করুন।'
            : 'You haven\'t set any budgets for this month. Setting limits is key to saving.',
        color: AppColors.primary,
      ));
    }

    final hasEmergencyGoal = goals.any((g) =>
        g.name.toLowerCase().contains('emergency') || g.name.contains('জরুরি'));
    if (!hasEmergencyGoal) {
      final recommendedAmount =
          summary.totalIncome > 0 ? (summary.totalIncome * 0.15) : 300000.0;
      final formattedRec = formatAmount(currency, recommendedAmount);
      recommendations.add(SmartRecommendationItem(
        icon: Icons.savings_rounded,
        title: isBangla
            ? 'জরুরি তহবিলের লক্ষ্য শুরু করুন'
            : 'Start a goal for Emergency Fund',
        desc: isBangla
            ? 'আপনার প্রোফাইলের ভিত্তিতে প্রতি মাসে $formattedRec সঞ্চয় করার পরামর্শ দেওয়া হচ্ছে।'
            : 'Based on your profile, saving $formattedRec monthly is recommended.',
        color: AppColors.success,
      ));
    }

    if (totalBudget > 0 && (totalBudgetSpent / totalBudget) >= 0.85) {
      recommendations.add(SmartRecommendationItem(
        icon: Icons.warning_amber_rounded,
        title: isBangla
            ? 'ক্যাটাগরি খরচ পর্যালোচনা করুন'
            : 'Review category spending',
        desc: isBangla
            ? 'আপনি মোট বাজেটের ৮৫% এর বেশি ব্যবহার করে ফেলেছেন। অপ্রয়োজনীয় ব্যয় সীমিত করুন।'
            : 'You have utilized over 85% of your total budget. Trim down on leisure categories.',
        color: AppColors.warning,
      ));
    }

    final hasBorrowedDebt =
        debts.any((d) => d.type == DebtType.borrowed && !d.isSettled);
    if (hasBorrowedDebt) {
      recommendations.add(SmartRecommendationItem(
        icon: Icons.payment_rounded,
        title: isBangla ? 'বকেয়া ঋণ পরিশোধ করুন' : 'Clear outstanding debts',
        desc: isBangla
            ? 'আপনার সক্রিয় বকেয়া ঋণ রয়েছে। এগুলো পরিশোধ করলে আপনার ট্রাস্ট স্কোর উন্নত হবে।'
            : 'You have active borrowed debts. Paying them off will improve your trust score.',
        color: AppColors.error,
      ));
    }

    if (recommendations.length < 2) {
      recommendations.add(SmartRecommendationItem(
        icon: Icons.security_rounded,
        title: isBangla
            ? 'সাবস্ক্রিপশন সার্ভিস ট্র্যাক করুন'
            : 'Track subscription services',
        desc: isBangla
            ? 'অব্যবহৃত সাবস্ক্রিপশন শনাক্ত করে খরচ সাশ্রয় করতে রিকারিং ট্যাব চেক করুন।'
            : 'Check your recurring tab to detect unused subscriptions and save up to 15% in costs.',
        color: AppColors.primary,
      ));
    }

    final isWide = MediaQuery.of(context).size.width > 1000;

    if (isWide) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.read(transactionsProvider.notifier).loadTransactions();
              ref.read(accountsProvider.notifier).loadAccounts();
              ref.read(budgetsProvider.notifier).loadBudgets();
              ref.read(debtsProvider.notifier).loadDebts();
              ref.read(categoriesProvider.notifier).loadCategories();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1360),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header welcome banner
                      _anim(
                        index: 0,
                        child: _webWelcomeHeader(context, fullName, alertCount),
                      ),
                      const SizedBox(height: 20),

                      // 1. Top Stats Row (4 Cards)
                      _anim(
                        index: 1,
                        child: _webStatsGrid(
                          context,
                          summary.totalBalance,
                          summary.totalIncome,
                          summary.totalExpense,
                          savingsAmount,
                          savingsRate,
                          currency,
                          effectiveHide,
                          toggleReveal,
                          primary,
                          isDark,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. Core Layout (Two Columns)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main workspace: insights and transaction activity.
                          Expanded(
                            flex: 7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _anim(
                                  index: 2,
                                  child: ExpenseChartDynamic(
                                    compact: false,
                                    showLegend: true,
                                    margin: EdgeInsets.zero,
                                    hideAmounts: effectiveHide,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _anim(
                                  index: 3,
                                  child: TransactionListDynamic(
                                    transactions: summary.recentTransactions,
                                    currency: currency,
                                    hideAmounts: effectiveHide,
                                    margin: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Compact planning panel.
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _anim(
                                  index: 4,
                                  child: FinancialHealthScore(
                                    score: healthScore,
                                    statusText: healthTrendText,
                                    detailText: healthDetailText,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (_showAiInsight) ...[
                                  _anim(
                                    index: 5,
                                    child: AiFinancialInsightsCard(
                                      insightText: aiInsightText,
                                      onSetLimit: () => context.go('/budget'),
                                      onDismiss: () => setState(
                                          () => _showAiInsight = false),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                _anim(
                                  index: 6,
                                  child: _webBudgetProgressSection(
                                    context,
                                    budgets,
                                    totalBudget,
                                    totalBudgetSpent,
                                    remainingBudget,
                                    budgetProgress,
                                    currency,
                                    effectiveHide,
                                    isDark,
                                    primary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _anim(
                                  index: 7,
                                  child: WeeklySpendingStreak(
                                    streakDays: streakDays,
                                    dailyStatus: dailyStatus,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _anim(
                                  index: 8,
                                  child: SpendingHeatmap(
                                      simulatedData: heatmapData),
                                ),
                                if (upcomingBills.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  _anim(
                                    index: 9,
                                    child: UpcomingBillsTimeline(bills: upcomingBills),
                                  ),
                                ],
                                if (recommendations.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  _anim(
                                    index: 10,
                                    child: SmartRecommendations(
                                        recommendations: recommendations),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(transactionsProvider.notifier).loadTransactions();
            ref.read(accountsProvider.notifier).loadAccounts();
            ref.read(budgetsProvider.notifier).loadBudgets();
            ref.read(debtsProvider.notifier).loadDebts();
            ref.read(categoriesProvider.notifier).loadCategories();
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _anim(
                    index: 0,
                    child: _appBar(
                        context, primary, alertCount, hideAmounts, isDark)),
              ),
              SliverToBoxAdapter(
                child: _anim(
                    index: 1,
                    child: _balanceCard(context, summary, currency,
                        effectiveHide, toggleReveal, primary, isDark)),
              ),
              SliverToBoxAdapter(
                child: DailyBudgetTrackerCard(settings: settings, currency: currency),
              ),
              SliverToBoxAdapter(
                child: _anim(
                    index: 2,
                    child: _accountsDebtRow(context, accounts, debts, currency,
                        effectiveHide, toggleReveal, isDark, primary)),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: _anim(
                    index: 3,
                    child: FinancialHealthScore(
                      score: healthScore,
                      statusText: healthTrendText,
                      detailText: healthDetailText,
                    ),
                  ),
                ),
              ),
              if (_showAiInsight)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: _anim(
                      index: 4,
                      child: AiFinancialInsightsCard(
                        insightText: aiInsightText,
                        onSetLimit: () => context.go('/budget'),
                        onDismiss: () =>
                            setState(() => _showAiInsight = false),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: _anim(
                    index: 5,
                    child: ExpenseChartDynamic(
                        compact: true, showLegend: true, hideAmounts: effectiveHide)),
              ),
              if (upcomingBills.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: _anim(
                      index: 6,
                      child: UpcomingBillsTimeline(bills: upcomingBills),
                    ),
                  ),
                ),
              if (recommendations.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: _anim(
                      index: 7,
                      child: SmartRecommendations(
                          recommendations: recommendations),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: _anim(
                    index: 8,
                    child: WeeklySpendingStreak(
                      streakDays: streakDays,
                      dailyStatus: dailyStatus,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: _anim(
                    index: 9,
                    child: SpendingHeatmap(simulatedData: heatmapData),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _anim(
                    index: 10,
                    child: TransactionListDynamic(
                      transactions: summary.recentTransactions,
                      currency: currency,
                      hideAmounts: effectiveHide,
                    )),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────
  Widget _appBar(BuildContext ctx, Color primary, int alertCount,
      bool hideAmounts, bool isDark) {
    final profile = ref.watch(userProfileProvider);
    final fullName = (profile['fullName'] ?? '').trim();
    final profileEmail = (profile['email'] ?? '').trim();
    final profilePhone = (profile['phone'] ?? '').trim();
    final photoBase64 = (profile['photoBase64'] ?? '').trim();
    final profileImage = _resolveProfileImage(photoBase64);

    // Determine display name: fullName > email > 'Dashboard'
    final firebaseUser = AuthService().currentUser;
    final displayName = fullName.isNotEmpty
        ? fullName
        : profileEmail.isNotEmpty
            ? profileEmail
            : (firebaseUser?.email ?? context.t('dashboard'));

    final contactLine = profilePhone.isNotEmpty
        ? profilePhone
        : profileEmail.isNotEmpty
            ? profileEmail
            : (firebaseUser?.email?.trim() ?? '');

    final initials = fullName.isEmpty
        ? (profileEmail.isNotEmpty ? profileEmail[0].toUpperCase() : '?')
        : fullName
            .split(' ')
            .where((e) => e.isNotEmpty)
            .take(2)
            .map((e) => e[0].toUpperCase())
            .join();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(children: [
        GestureDetector(
          onTap: () => ctx.push('/profile'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: photoBase64.isEmpty
                  ? LinearGradient(colors: [
                      primary,
                      Color.lerp(primary, Colors.indigo, 0.4)!
                    ], begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : null,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                    color: primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: profileImage != null
                  ? Image(
                      image: profileImage,
                      fit: BoxFit.cover,
                      width: 44,
                      height: 44,
                    )
                  : Center(
                      child: Text(initials.isEmpty ? '?' : initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800))),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_greeting(context),
                style: AppTextStyles.caption.copyWith(
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                    fontSize: 11)),
            Text(displayName,
                style: AppTextStyles.h2.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Theme.of(ctx).colorScheme.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            if (contactLine.isNotEmpty)
              Text(contactLine,
                  style: AppTextStyles.caption.copyWith(
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.35),
                      fontSize: 9),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ],
        )),
        if (hideAmounts) ...[
          // eye button now lives in balance card, not nav bar
          const SizedBox(width: 6),
        ],
        _navBtn(ctx, Icons.notifications_outlined, isDark,
            () => ctx.push('/notifications'),
            badge: alertCount > 0),
        const SizedBox(width: 6),
        _navBtn(ctx, Icons.search_rounded, isDark, () => ctx.push('/search')),
        const SizedBox(width: 6),
        _navBtn(ctx, Icons.auto_awesome_rounded, isDark,
            () => ctx.push('/ai-assistant')),
      ]),
    );
  }

  Widget _navBtn(
      BuildContext ctx, IconData icon, bool isDark, VoidCallback onTap,
      {bool badge = false}) {
    return Stack(children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Icon(icon,
              size: 19,
              color:
                  Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      ),
      if (badge)
        Positioned(
            right: 8,
            top: 8,
            child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Theme.of(ctx).scaffoldBackgroundColor,
                        width: 1)))),
    ]);
  }

  // â”€â”€ Compact Balance Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _balanceCard(
      BuildContext context,
      DashboardSummary summary,
      String currency,
      bool hideAmounts,
      VoidCallback toggleReveal,
      Color primary,
      bool isDark) {
    final hasMonthlyData =
        summary.monthIncome > 0 || summary.monthExpense > 0;
    final heroIncome =
        hasMonthlyData ? summary.monthIncome : summary.totalIncome;
    final heroExpense =
        hasMonthlyData ? summary.monthExpense : summary.totalExpense;
    final savingsRate = heroIncome > 0
        ? ((heroIncome - heroExpense) / heroIncome * 100).clamp(0.0, 100.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          primary,
          Color.lerp(primary, Colors.teal.shade700, 0.3)!,
          Color.lerp(primary, Colors.indigo.shade800, 0.5)!
        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: primary.withValues(alpha: 0.35),
              blurRadius: 22,
              spreadRadius: -4,
              offset: const Offset(0, 10))
        ],
      ),
      child: Stack(children: [
        Positioned(
            top: -30,
            right: -20,
            child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05)))),
        Positioned(
            bottom: -25,
            left: -15,
            child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04)))),
        Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 15)),
              const SizedBox(width: 9),
              Expanded(
                  child: Text(context.t('total_balance'),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500))),
              if (summary.totalIncome > 0)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                        context.t('saved_percent',
                            params: {'value': savingsRate.toStringAsFixed(0)}),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700))),
              const SizedBox(width: 8),
              GestureDetector(
                  onTap: () {
                    // Toggle hide amounts in settings
                    final current =
                        ref.read(settingsProvider)['hideAmounts'] == true;
                    ref
                        .read(settingsProvider.notifier)
                        .updateHideAmounts(!current);
                    // Also reset local reveal state
                    setState(() => _revealAmounts = false);
                  },
                  child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9)),
                      child: Icon(
                          hideAmounts
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 14))),
            ]),
            const SizedBox(height: 10),
            // Balance amount
            GestureDetector(
              onTap: toggleReveal,
              behavior: HitTestBehavior.translucent,
              child: Text(
                formatAmount(currency, summary.totalBalance,
                    decimals: 2, hide: hideAmounts),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                    height: 1.0),
              ),
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.13)),
            const SizedBox(height: 14),
            // Income / Expense
            Row(children: [
              Expanded(
                  child: _heroStat(
                      context.t('income'),
                      heroIncome,
                      Icons.arrow_downward_rounded,
                      Colors.greenAccent.shade100,
                      currency,
                      hideAmounts,
                      toggleReveal,
                      false)),
              Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.15)),
              Expanded(
                  child: _heroStat(
                      context.t('expense'),
                      heroExpense,
                      Icons.arrow_upward_rounded,
                      Colors.red.shade100,
                      currency,
                      hideAmounts,
                      toggleReveal,
                      true)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _heroStat(String label, num amount, IconData icon, Color amtColor,
      String currency, bool hideAmounts, VoidCallback onTap, bool alignRight) {
    return Padding(
      padding: EdgeInsets.only(
          left: alignRight ? 16 : 0, right: alignRight ? 0 : 16),
      child: Row(
        mainAxisAlignment:
            alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!alignRight)
            Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, color: Colors.white, size: 14)),
          Column(
            crossAxisAlignment:
                alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 10,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.translucent,
                  child: Text(
                      formatAmount(currency, amount,
                          decimals: 0, hide: hideAmounts),
                      style: TextStyle(
                          color: amtColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3))),
            ],
          ),
          if (alignRight)
            Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, color: Colors.white, size: 14)),
        ],
      ),
    );
  }

  Widget _accountsDebtRow(
      BuildContext context,
      List<AccountModel> accounts,
      List debts,
      String currency,
      bool hideAmounts,
      VoidCallback toggleReveal,
      bool isDark,
      Color primary) {
    final splitGroups = ref.watch(splitGroupsProvider);
    final goals = ref.watch(goalsProvider);
    final allBudgets = ref.watch(budgetsProvider);
    final allTransactions = ref.watch(transactionsProvider);
    final profile = ref.watch(userProfileProvider);

    final now = DateTime.now();
    final monthBudgets = allBudgets
        .where((b) => b.month.year == now.year && b.month.month == now.month)
        .toList();

    // Accounts totals
    final totalBalance = accounts.fold<double>(0, (sum, a) => sum + a.balance);
    final cashTotal = accounts
        .where((a) => a.type == AccountType.cash)
        .fold<double>(0, (s, a) => s + a.balance);
    final onlineTotal = accounts
        .where((a) => a.type != AccountType.cash)
        .fold<double>(0, (s, a) => s + a.balance);

    // Split Expenses totals
    double totalSplitSpent = 0;
    double yourSplitShare = 0;
    double netOwedAmount = 0;
    final splitRepo = ref.read(splitExpenseRepositoryProvider);

    for (final group in splitGroups) {
      final expenses = splitRepo.getExpensesByGroup(group.id);
      final userMemberName = group.getUserMemberName(profile);
      final hasYou = group.members.contains(userMemberName);

      final groupSpent = expenses.fold<double>(0, (sum, e) => sum + e.amount);
      totalSplitSpent += groupSpent;

      if (hasYou) {
        final groupYourShare = expenses.fold<double>(0, (sum, expense) {
          final share = expense.splitAmong.isEmpty
              ? 0.0
              : expense.amount / expense.splitAmong.length;
          return expense.splitAmong.contains(userMemberName)
              ? sum + share
              : sum;
        });
        yourSplitShare += groupYourShare;

        final settlements = SplitSettlement.calculate(expenses, group.members);
        for (final s in settlements) {
          if (s.from == userMemberName) {
            netOwedAmount -= s.amount;
          } else if (s.to == userMemberName) {
            netOwedAmount += s.amount;
          }
        }
      }
    }

    // Debts totals
    double lent = 0, borrowed = 0;
    for (final d in debts) {
      if (d.isSettled) continue;
      final rem = (d.amount - d.paidAmount).clamp(0.0, d.amount);
      if (d.type == DebtType.lent) {
        lent += rem;
      } else {
        borrowed += rem;
      }
    }
    final activeDebts = debts.where((d) => !d.isSettled).length;
    final lentCount =
        debts.where((d) => !d.isSettled && d.type == DebtType.lent).length;
    final borrowedCount =
        debts.where((d) => !d.isSettled && d.type == DebtType.borrowed).length;

    // Goals totals
    final activeGoals = goals.where((g) => !g.isCompleted).toList();
    final totalGoalTarget =
        activeGoals.fold<double>(0, (sum, g) => sum + g.targetAmount);
    final totalGoalSaved =
        activeGoals.fold<double>(0, (sum, g) => sum + g.currentAmount);
    final goalPercentage =
        totalGoalTarget > 0 ? (totalGoalSaved / totalGoalTarget) : 0.0;

    // Budget totals
    final totalBudget =
        monthBudgets.fold<double>(0, (sum, b) => sum + b.amount);
    final totalBudgetSpent =
        monthBudgets.fold<double>(0, (sum, b) => sum + b.getSpent(allTransactions));
    final remainingBudget =
        (totalBudget - totalBudgetSpent).clamp(0.0, double.infinity);
    final budgetProgress =
        totalBudget > 0 ? (totalBudgetSpent / totalBudget) : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left Card (Accounts / Split Expenses) ───────────────────────
          Expanded(
            child: _surfCard(
              context,
              isDark,
              child: SizedBox(
                height: 135,
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _leftPageController,
                        onPageChanged: (idx) =>
                            setState(() => _leftPageIndex = idx),
                        children: [
                          _accountsCardContent(
                              context,
                              accounts,
                              totalBalance,
                              cashTotal,
                              onlineTotal,
                              currency,
                              hideAmounts,
                              toggleReveal,
                              primary),
                          _splitExpensesCardContent(
                              context,
                              splitGroups,
                              totalSplitSpent,
                              yourSplitShare,
                              netOwedAmount,
                              currency,
                              hideAmounts,
                              toggleReveal,
                              primary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildPageIndicator(2, _leftPageIndex, primary),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── Right Card (Debts / Goals / Budget) ──────────────────────────
          Expanded(
            child: _surfCard(
              context,
              isDark,
              child: SizedBox(
                height: 135,
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _rightPageController,
                        onPageChanged: (idx) =>
                            setState(() => _rightPageIndex = idx),
                        children: [
                          _debtsCardContent(
                              context,
                              lent,
                              borrowed,
                              activeDebts,
                              lentCount,
                              borrowedCount,
                              currency,
                              hideAmounts,
                              toggleReveal,
                              primary),
                          _goalsCardContent(
                              context,
                              goals,
                              totalGoalTarget,
                              totalGoalSaved,
                              goalPercentage,
                              currency,
                              hideAmounts,
                              toggleReveal,
                              primary),
                          _budgetsCardContent(
                              context,
                              monthBudgets,
                              totalBudget,
                              totalBudgetSpent,
                              remainingBudget,
                              budgetProgress,
                              currency,
                              hideAmounts,
                              toggleReveal,
                              primary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildPageIndicator(3, _rightPageIndex, primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountsCardContent(
      BuildContext context,
      List<AccountModel> accounts,
      double totalBalance,
      double cashTotal,
      double onlineTotal,
      String currency,
      bool hideAmounts,
      VoidCallback toggleReveal,
      Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.account_balance_wallet_rounded,
                color: primary, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(context.t('accounts'),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface)),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.push('/accounts'),
              child:
                  Icon(Icons.chevron_right_rounded, size: 16, color: primary),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: toggleReveal,
                behavior: HitTestBehavior.translucent,
                child: Text(
                  accounts.isEmpty
                      ? context.t('no_accounts')
                      : formatAmount(currency, totalBalance, hide: hideAmounts),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: accounts.isEmpty ? 12 : 18,
                    fontWeight:
                        accounts.isEmpty ? FontWeight.w600 : FontWeight.w800,
                    letterSpacing: -0.4,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            if (accounts.length >= 2)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _showTransferPicker(accounts, currency),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz_rounded,
                            size: 11, color: primary),
                        const SizedBox(width: 3),
                        Text(
                          context.t('transfer'),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          accounts.isEmpty
              ? context.t('add_first_account')
              : context.t('accounts_count',
                  params: {'count': accounts.length.toString()}),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
        if (accounts.isNotEmpty) ...[
          const SizedBox(height: 6),
          _accountMiniLine(context, context.t('cash'), cashTotal, currency,
              hideAmounts, toggleReveal),
          const SizedBox(height: 3),
          _accountMiniLine(context, context.t('online'), onlineTotal, currency,
              hideAmounts, toggleReveal),
        ],
      ],
    );
  }

  Widget _splitExpensesCardContent(
      BuildContext context,
      List<SplitGroup> splitGroups,
      double totalSplitSpent,
      double yourSplitShare,
      double netOwedAmount,
      String currency,
      bool hideAmounts,
      VoidCallback toggleReveal,
      Color primary) {
    final bn = Localizations.localeOf(context).languageCode == 'bn';
    final isOwed = netOwedAmount > 0;
    final absOwed = netOwedAmount.abs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.call_split_rounded,
                color: Colors.blue, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(bn ? 'স্প্লিট খরচ' : 'Split Expenses',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface)),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.push('/split-expenses'),
              child: const Icon(Icons.chevron_right_rounded,
                  size: 16, color: Colors.blue),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: toggleReveal,
          behavior: HitTestBehavior.translucent,
          child: Text(
            formatAmount(currency, totalSplitSpent, hide: hideAmounts),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          splitGroups.isEmpty
              ? (bn ? 'কোনো গ্রুপ নেই' : 'No groups yet')
              : (bn
                  ? '${splitGroups.length} টি গ্রুপ'
                  : '${splitGroups.length} active group${splitGroups.length > 1 ? 's' : ''}'),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
        if (splitGroups.isNotEmpty) ...[
          const SizedBox(height: 6),
          _splitMiniLine(
            context,
            bn ? 'আপনার অংশ' : 'Your Share',
            yourSplitShare,
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            currency,
            hideAmounts,
          ),
          const SizedBox(height: 3),
          _splitMiniLine(
            context,
            absOwed < 0.01
                ? (bn ? 'নিষ্পত্তি করা হয়েছে' : 'Settled')
                : (isOwed
                    ? (bn ? 'পাবেন' : 'To Receive')
                    : (bn ? 'দেবেন' : 'To Pay')),
            absOwed,
            absOwed < 0.01
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                : (isOwed ? AppColors.success : AppColors.error),
            currency,
            hideAmounts,
          ),
        ],
      ],
    );
  }

  Widget _debtsCardContent(
      BuildContext context,
      double lent,
      double borrowed,
      int activeDebts,
      int lentCount,
      int borrowedCount,
      String currency,
      bool hideAmounts,
      VoidCallback toggleReveal,
      Color primary) {
    final bn = Localizations.localeOf(context).languageCode == 'bn';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardHeader2(context, context.t('debts'), Icons.handshake_rounded,
            AppColors.warning, () => context.push('/debts')),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: toggleReveal,
          behavior: HitTestBehavior.translucent,
          child: Text(
            formatAmount(currency, lent + borrowed, hide: hideAmounts),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          activeDebts == 0
              ? (bn ? 'কোনো সক্রিয় ঋণ নেই' : 'No active debts')
              : context
                  .t('due_count', params: {'count': activeDebts.toString()}),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
        if (lent > 0 || borrowed > 0) ...[
          const SizedBox(height: 6),
          _debtMiniLine(context, context.t('to_receive'), lent,
              AppColors.success, currency, hideAmounts, lentCount),
          const SizedBox(height: 3),
          _debtMiniLine(context, context.t('to_pay'), borrowed, AppColors.error,
              currency, hideAmounts, borrowedCount),
        ],
      ],
    );
  }

  Widget _goalsCardContent(
      BuildContext context,
      List<GoalModel> goals,
      double totalTarget,
      double totalSaved,
      double percentage,
      String currency,
      bool hideAmounts,
      VoidCallback toggleReveal,
      Color primary) {
    final bn = Localizations.localeOf(context).languageCode == 'bn';
    final activeCount = goals.where((g) => !g.isCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardHeader2(
            context,
            bn ? 'লক্ষ্যসমূহ' : 'Goals',
            Icons.track_changes_rounded,
            Colors.purple,
            () => context.push('/goals')),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: toggleReveal,
          behavior: HitTestBehavior.translucent,
          child: Text(
            formatAmount(currency, totalSaved, hide: hideAmounts),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          activeCount == 0
              ? (bn ? 'কোনো সক্রিয় লক্ষ্য নেই' : 'No active goals')
              : (bn
                  ? '$activeCount টি সক্রিয় লক্ষ্য'
                  : '$activeCount active goal${activeCount > 1 ? 's' : ''}'),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
        if (goals.isNotEmpty) ...[
          const SizedBox(height: 6),
          _goalProgressMiniLine(
            context,
            bn ? 'মোট লক্ষ্য' : 'Total Target',
            totalTarget,
            currency,
            hideAmounts,
          ),
          const SizedBox(height: 3),
          _goalPercentMiniLine(
            context,
            bn ? 'অগ্রগতি' : 'Progress',
            percentage,
          ),
        ],
      ],
    );
  }

  Widget _budgetsCardContent(
      BuildContext context,
      List<BudgetModel> monthBudgets,
      double totalBudget,
      double totalSpent,
      double remainingBudget,
      double budgetProgress,
      String currency,
      bool hideAmounts,
      VoidCallback toggleReveal,
      Color primary) {
    final bn = Localizations.localeOf(context).languageCode == 'bn';
    final budgetCount = monthBudgets.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardHeader2(
            context,
            bn ? 'বাজেট' : 'Budget',
            Icons.donut_large_rounded,
            Colors.teal,
            () => context.push('/budget')),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: toggleReveal,
          behavior: HitTestBehavior.translucent,
          child: Text(
            formatAmount(currency, remainingBudget, hide: hideAmounts),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          budgetCount == 0
              ? (bn ? 'কোনো বাজেট সেট নেই' : 'No budget set')
              : (bn
                  ? 'অবশিষ্ট বাজেট (মোট $budgetCount টি)'
                  : 'Remaining of $budgetCount budget${budgetCount > 1 ? 's' : ''}'),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
        if (monthBudgets.isNotEmpty) ...[
          const SizedBox(height: 6),
          _budgetProgressMiniLine(
            context,
            bn ? 'মোট বাজেট' : 'Total Budget',
            totalBudget,
            currency,
            hideAmounts,
            Colors.teal,
          ),
          const SizedBox(height: 3),
          _budgetProgressMiniLine(
            context,
            bn ? 'মোট খরচ' : 'Spent',
            totalSpent,
            currency,
            hideAmounts,
            budgetProgress > 1.0 ? AppColors.error : Colors.teal.shade300,
          ),
        ],
      ],
    );
  }

  Widget _buildPageIndicator(int count, int currentIndex, Color activeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          height: 4,
          width: isActive ? 12 : 4,
          decoration: BoxDecoration(
            color: isActive ? activeColor : activeColor.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _splitMiniLine(
    BuildContext context,
    String label,
    double amount,
    Color color,
    String currency,
    bool hideAmounts,
  ) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5))),
        const Spacer(),
        Text(
          formatAmount(currency, amount, hide: hideAmounts),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.2),
        ),
      ],
    );
  }

  Widget _goalProgressMiniLine(
    BuildContext context,
    String label,
    double amount,
    String currency,
    bool hideAmounts,
  ) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration:
              const BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5))),
        const Spacer(),
        Text(
          formatAmount(currency, amount, hide: hideAmounts),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.purple,
              letterSpacing: -0.2),
        ),
      ],
    );
  }

  Widget _goalPercentMiniLine(
    BuildContext context,
    String label,
    double percentage,
  ) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
              color: Colors.purpleAccent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5))),
        const Spacer(),
        Text(
          '${(percentage * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.purpleAccent,
              letterSpacing: -0.2),
        ),
      ],
    );
  }

  Widget _budgetProgressMiniLine(
    BuildContext context,
    String label,
    double amount,
    String currency,
    bool hideAmounts,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5))),
        const Spacer(),
        Text(
          formatAmount(currency, amount, hide: hideAmounts),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.2),
        ),
      ],
    );
  }

  void _showTransferPicker(List<AccountModel> accounts, String currency) {
    AccountModel? fromAccount;
    AccountModel? toAccount;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              maxWidth: 560,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(context.t('transfer_funds'), style: AppTextStyles.h5),
                  const SizedBox(height: 16),
                  // From account
                  Text(context.t('from_account'),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.45))),
                  const SizedBox(height: 8),
                  _buildAccountChips(
                      ctx,
                      accounts,
                      fromAccount,
                      currency,
                      (a) => setModalState(() {
                            fromAccount = a;
                            if (toAccount == a) toAccount = null;
                          })),
                  const SizedBox(height: 14),
                  // To account
                  Text(context.t('to_account'),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.45))),
                  const SizedBox(height: 8),
                  _buildAccountChips(
                      ctx,
                      accounts.where((a) => a != fromAccount).toList(),
                      toAccount,
                      currency,
                      (a) => setModalState(() => toAccount = a)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: fromAccount != null && toAccount != null
                          ? () {
                              Navigator.pop(ctx);
                              _showTransfer(fromAccount!, toAccount!, currency);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(context.t('continue_action')),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountChips(
    BuildContext context,
    List<AccountModel> accounts,
    AccountModel? selected,
    String currency,
    ValueChanged<AccountModel> onSelect,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: accounts.map((a) {
        final isSelected = selected == a;
        final nickname = a.nickname?.isNotEmpty == true ? a.nickname! : a.name;
        final accountNumberSuffix = a.accountNumber?.isNotEmpty == true
            ? ' (${a.accountNumber!.length > 4 ? a.accountNumber!.substring(a.accountNumber!.length - 4) : a.accountNumber})'
            : '';
        final displayName = '$nickname$accountNumberSuffix';
        return GestureDetector(
          onTap: () => onSelect(a),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? primary.withValues(alpha: 0.12)
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(a.icon ?? '💳', style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? primary
                              : Theme.of(context).colorScheme.onSurface,
                        )),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  formatAmount(currency, a.balance),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _surfCard(BuildContext context, bool isDark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: child,
    );
  }

  Widget _webWelcomeHeader(
      BuildContext context, String fullName, int alertCount) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final greetingPrefix = _greeting(context);
    final greetingName = fullName.isNotEmpty ? fullName : 'User';
    final dateStr = DateFormat('EEEE, MMMM dd').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.55)
              : AppColors.lightBorder.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.waving_hand_rounded, color: primary, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greetingPrefix, $greetingName',
              style: AppTextStyles.headingLg.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 13,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: AppTextStyles.bodySm.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ],
            ),
          ),
          if (alertCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: isDark ? 0.16 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined,
                      size: 15, color: AppColors.error),
                  const SizedBox(width: 7),
                  Text(
                    Localizations.localeOf(context).languageCode == 'bn'
                        ? '$alertCount টি সতর্কতা'
                        : '$alertCount alerts',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _webStatsGrid(
    BuildContext context,
    num totalBalance,
    num income,
    num expense,
    num savings,
    num savingsRate,
    String currency,
    bool hideAmounts,
    VoidCallback toggleReveal,
    Color primary,
    bool isDark,
  ) {
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    return Row(
      children: [
        Expanded(
          child: _webStatCard(
            context,
            title: context.t('total_balance'),
            value: totalBalance,
            currency: currency,
            hideAmounts: hideAmounts,
            icon: Icons.account_balance_wallet_rounded,
            iconColor: primary,
            trendLabel: isBangla ? 'ব্যালেন্স' : 'Balance',
            trendColor: primary,
            onTap: toggleReveal,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _webStatCard(
            context,
            title: context.t('income'),
            value: income,
            currency: currency,
            hideAmounts: hideAmounts,
            icon: Icons.arrow_downward_rounded,
            iconColor: AppColors.success,
            trendLabel: isBangla ? 'আয়' : 'Income',
            trendColor: AppColors.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _webStatCard(
            context,
            title: context.t('expense'),
            value: expense,
            currency: currency,
            hideAmounts: hideAmounts,
            icon: Icons.arrow_upward_rounded,
            iconColor: AppColors.error,
            trendLabel: isBangla ? 'ব্যয়' : 'Expense',
            trendColor: AppColors.error,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _webStatCard(
            context,
            title: isBangla ? 'নেট সঞ্চয়' : 'Net Savings',
            value: savings,
            currency: currency,
            hideAmounts: hideAmounts,
            icon: Icons.savings_rounded,
            iconColor: Colors.purple,
            trendLabel: isBangla
                ? '${savingsRate.toStringAsFixed(0)}% সঞ্চিত'
                : '${savingsRate.toStringAsFixed(0)}% saved',
            trendColor: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _webStatCard(
    BuildContext context, {
    required String title,
    required num value,
    required String currency,
    required bool hideAmounts,
    required IconData icon,
    required Color iconColor,
    required String trendLabel,
    required Color trendColor,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : AppColors.lightBorder.withValues(alpha: 0.7),
        ),
        boxShadow: isDark ? AppColors.shadowDarkSm : AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: isDark ? 0.15 : 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trendLabel,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: trendColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: AppTextStyles.bodySm.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.translucent,
            child: Text(
              formatAmount(currency, value, decimals: 0, hide: hideAmounts),
              style: AppTextStyles.amountMedium.copyWith(
                fontSize: 26,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _webBudgetProgressSection(
    BuildContext context,
    List budgets,
    double totalBudget,
    double totalBudgetSpent,
    double remainingBudget,
    double budgetProgress,
    String currency,
    bool hideAmounts,
    bool isDark,
    Color primary,
  ) {
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    final percentage = (budgetProgress * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : AppColors.lightBorder.withValues(alpha: 0.7),
        ),
        boxShadow: isDark ? AppColors.shadowDarkSm : AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBangla ? 'বাজেট ওভারভিউ' : 'Budget overview',
                style: AppTextStyles.headingSm.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (budgetProgress > 0.9 ? AppColors.error : primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: budgetProgress > 0.9 ? AppColors.error : primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.lightSurfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: budgetProgress.clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: budgetProgress > 0.9
                          ? [
                              AppColors.error,
                              AppColors.error.withValues(alpha: 0.7)
                            ]
                          : [primary, primary.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (budgetProgress > 0.9 ? AppColors.error : primary)
                                .withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _webBudgetMiniStat(
                  context,
                  isBangla ? 'মোট বাজেট' : 'Total Limit',
                  formatAmount(currency, totalBudget, hide: hideAmounts),
                  isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              Container(
                  width: 1,
                  height: 30,
                  color: isDark ? Colors.white10 : Colors.black12),
              const SizedBox(width: 16),
              Expanded(
                child: _webBudgetMiniStat(
                  context,
                  isBangla ? 'মোট ব্যয়' : 'Total Spent',
                  formatAmount(currency, totalBudgetSpent, hide: hideAmounts),
                  budgetProgress > 0.9 ? AppColors.error : primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _webBudgetMiniStat(
      BuildContext context, String label, String value, Color valueColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.overline.copyWith(
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.amountSmall.copyWith(
            fontSize: 16,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _cardHeader2(BuildContext context, String title, IconData icon,
      Color iconColor, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 14)),
      const SizedBox(width: 8),
      Expanded(
          child: Text(title,
              style: AppTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface))),
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
            onTap: onTap,
            child:
                Icon(Icons.chevron_right_rounded, size: 16, color: iconColor)),
      ),
    ]);
  }

  Widget _debtMiniLine(
    BuildContext context,
    String label,
    double amount,
    Color color,
    String currency,
    bool hideAmounts,
    int count,
  ) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5))),
        const Spacer(),
        Text(
          formatAmount(currency, amount, hide: hideAmounts),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.2),
        ),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ],
    );
  }

  Widget _accountMiniLine(
    BuildContext context,
    String label,
    double amount,
    String currency,
    bool hideAmounts,
    VoidCallback onTap,
  ) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.translucent,
          child: Text(
            formatAmount(currency, amount, hide: hideAmounts),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }

  void _showTransfer(AccountModel from, AccountModel to, String currency) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: 560,
          ),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 12),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(context.t('transfer_funds'), style: AppTextStyles.h5),
              const SizedBox(height: 4),
              Text(
                '${from.nickname?.isNotEmpty == true ? from.nickname! : from.name}${from.accountNumber?.isNotEmpty == true ? " (${from.accountNumber!.length > 4 ? from.accountNumber!.substring(from.accountNumber!.length - 4) : from.accountNumber})" : ""}  →  ${to.nickname?.isNotEmpty == true ? to.nickname! : to.name}${to.accountNumber?.isNotEmpty == true ? " (${to.accountNumber!.length > 4 ? to.accountNumber!.substring(to.accountNumber!.length - 4) : to.accountNumber})" : ""}',
                style: AppTextStyles.body2.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 16),
              TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: context.t('amount'),
                      prefixText: '$currency ',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)))),
              const SizedBox(height: 14),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final enteredAmount = double.tryParse(ctrl.text.trim()) ?? 0;
                      final amountInPaisa = (enteredAmount * 100).round();
                      if (enteredAmount <= 0 || amountInPaisa <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(context.t('enter_valid_amount'))));
                        return;
                      }
                      if (amountInPaisa > from.balance) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(context.t('insufficient_balance'))));
                        return;
                      }
                      await ref
                          .read(accountsProvider.notifier)
                          .updateBalance(from.id, from.balance - amountInPaisa);
                      await ref
                          .read(accountsProvider.notifier)
                          .updateBalance(to.id, to.balance + amountInPaisa);

                      final fromName = from.nickname?.isNotEmpty == true
                          ? from.nickname!
                          : from.name;
                      final toName = to.nickname?.isNotEmpty == true
                          ? to.nickname!
                          : to.name;
                      final now = DateTime.now();
                      final tx = TransactionModel(
                        id: now.millisecondsSinceEpoch.toString(),
                        type: TransactionType.transfer,
                        amount: amountInPaisa,
                        categoryId: '',
                        accountId: from.id,
                        toAccountId: to.id,
                        date: now,
                        note: 'Transfer: $fromName → $toName',
                        createdAt: now,
                        updatedAt: now,
                      );
                      await ref
                          .read(transactionsProvider.notifier)
                          .addTransaction(tx);

                      if (!mounted || !ctx.mounted) return;
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: Text(context.t('confirm_transfer')),
                  )),
            ]),
          ),
        ),
      ),
    );
  }

  int _alertCount(DashboardSummary summary, List budgets, List debts, List transactions) {
    final accounts = ref.read(accountsProvider);
    int n = 0;
    if (accounts.isNotEmpty && summary.totalBalance < 0) {
      n++;
    }
    if (budgets.any((b) => b.amount > 0 && b.getSpent(transactions) / b.amount >= 0.9)) {
      n++;
    }
    final now = DateTime.now();
    if (debts.any((d) {
      return d.dueDate != null &&
          !d.isSettled &&
          d.dueDate!.isBefore(now.add(const Duration(days: 3)));
    })) {
      n++;
    }
    return n;
  }

  String _greeting(BuildContext context) {
    final h = DateTime.now().hour;
    if (h < 5) return context.t('good_night');
    if (h < 12) return context.t('good_morning');
    if (h < 17) return context.t('good_afternoon');
    if (h < 21) return context.t('good_evening');
    return context.t('good_night');
  }

  ImageProvider? _resolveProfileImage(String photoBase64) {
    if (photoBase64.isEmpty) {
      _profileImage = null;
      _profileImageCacheKey = null;
      return null;
    }
    if (_profileImageCacheKey == photoBase64 && _profileImage != null) {
      return _profileImage;
    }
    try {
      _profileImage = MemoryImage(base64Decode(photoBase64));
      _profileImageCacheKey = photoBase64;
      return _profileImage;
    } catch (_) {
      _profileImage = null;
      _profileImageCacheKey = null;
      return null;
    }
  }

  void _checkAndRequestNotificationPermission() async {
    if (kIsWeb) return;

    // Check if permission is already granted
    if (await Permission.notification.isGranted) return;

    // Request permission, which will trigger the OS dialog on Android 13+
    await Permission.notification.request();
  }

  void _checkAndShowSmsPermissionDialog() async {
    if (kIsWeb) return;
    // Wait a short moment to let screen transition complete smoothly
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final settings = ref.read(settingsProvider);
    final dialogShown = settings['smsPermissionDialogShown'] ?? false;
    final smsTrack = settings['smsTrack'] ?? false;

    // Show only if dialog hasn't been shown before and SMS tracking is disabled
    if (!dialogShown && !smsTrack) {
      if (!mounted) return;

      // Mark dialog as shown first so we don't show it again even if permission is denied or dismissed
      await ref
          .read(settingsProvider.notifier)
          .updateSmsPermissionDialogShown(true);

      if (!mounted) return;
      _showSmsPermissionExplanationDialog();
    }
  }

  void _showSmsPermissionExplanationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Ensure they make a choice
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          constraints: const BoxConstraints(maxWidth: 500),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          title: Text(
            ctx.t('sms_permission_dialog_title'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ctx.t('sms_permission_dialog_body'),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actionsPadding:
              const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          actions: [
            // Maybe Later
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.grey[400] : Colors.grey[600],
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                ctx.t('sms_permission_dialog_deny'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            // Enable Now
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _enableSmsTrackingFlow();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: Text(
                ctx.t('sms_permission_dialog_allow'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _enableSmsTrackingFlow() async {
    // Persist true first to handle process kills on permission grant
    await ref.read(settingsProvider.notifier).updateSmsTrack(true);

    final granted = await SmsService.requestPermission();
    if (!granted) {
      // Revert to false if not granted/cancelled
      await ref.read(settingsProvider.notifier).updateSmsTrack(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('sms_permission_denied'))),
        );
      }
      return;
    }

    // Check and request standard notification permission on Android 13+
    final notifGranted = await Permission.notification.request().isGranted;
    if (!notifGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t('language') == 'bn'
                ? 'লেনদেন নিশ্চিতকরণের জন্য নোটিফিকেশন পারমিশন প্রয়োজন'
                : 'Notification permission is required to ask for transaction confirmation',
          ),
        ),
      );
    }

    // Request ignore battery optimizations exemption
    final batteryIgnored =
        await Permission.ignoreBatteryOptimizations.request().isGranted;
    if (!batteryIgnored && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t('language') == 'bn'
                ? 'ব্যাটারি অপ্টিমাইজেশন সচল থাকায় ব্যাকগ্রাউন্ডে লেনদেন ট্র্যাকিং বিঘ্নিত হতে পারে।'
                : 'Battery optimization is active. Auto-import might not be 100% reliable in the background.',
          ),
        ),
      );
    }

    // If still running (or returning granted), start listening
    await SmsService().init();
    if (mounted) {
      _showBackgroundRunningTipsDialog(context);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncSmsTrackPermission();
    }
  }

  Future<void> _syncSmsTrackPermission() async {
    final settings = ref.read(settingsProvider);
    final smsTrack = settings['smsTrack'] ?? false;
    if (smsTrack) {
      final isGranted = await SmsService.isPermissionGranted();
      if (!isGranted && mounted) {
        await ref.read(settingsProvider.notifier).updateSmsTrack(false);
        SmsService().stopListening();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.t('language') == 'bn'
                  ? 'এসএমএস অটো-ইমপোর্ট অনুমতি না পাওয়ায় এটি বন্ধ করা হয়েছে।'
                  : 'SMS Auto-Import has been disabled as permission was not granted.',
            ),
          ),
        );
      }
    }
  }

  void _showBackgroundRunningTipsDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          constraints: const BoxConstraints(maxWidth: 480),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(
            Icons.info_outline_rounded,
            size: 40,
            color: AppColors.info,
          ),
          title: Text(
            ctx.t('language') == 'bn'
                ? 'ব্যাকগ্রাউন্ড রানিং টিপস'
                : 'Background Run Tips',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            ctx.t('background_running_tips'),
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  ctx.t('language') == 'bn' ? 'ঠিক আছে' : 'OK',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
