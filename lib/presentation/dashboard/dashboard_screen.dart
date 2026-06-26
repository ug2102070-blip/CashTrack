// lib/presentation/dashboard/dashboard_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  bool _revealAmounts = false;
  ImageProvider? _profileImage;
  String? _profileImageCacheKey;
  late final PageController _leftPageController;
  late final PageController _rightPageController;
  int _leftPageIndex = 0;
  int _rightPageIndex = 0;

  // Pre-created animations to avoid creating new CurvedAnimation objects
  // on every build() call — which leaks InheritedWidget dependents and
  // causes '_dependents.isEmpty' assertion failures.
  static const List<int> _animDelays = [0, 60, 130, 200, 270];
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
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
      }
    });
  }

  @override
  void dispose() {
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
    return FadeTransition(
      opacity: _fadeAnims[index],
      child: SlideTransition(
        position: _slideAnims[index],
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
    final profile = ref.watch(userProfileProvider);
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
    final alertCount = _alertCount(summary, budgets, debts);

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
                child: _anim(
                    index: 2,
                    child: _accountsDebtRow(context, accounts, debts, currency,
                        effectiveHide, toggleReveal, isDark, primary)),
              ),
              SliverToBoxAdapter(
                child: _anim(
                    index: 3,
                    child: const ExpenseChartDynamic(
                        compact: true, showLegend: true)),
              ),
              SliverToBoxAdapter(
                child: _anim(
                    index: 4,
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
    final savingsRate = summary.totalIncome > 0
        ? ((summary.totalIncome - summary.totalExpense) /
                summary.totalIncome *
                100)
            .clamp(0.0, 100.0)
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
                      summary.totalIncome,
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
                      summary.totalExpense,
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

  Widget _heroStat(String label, double amount, IconData icon, Color amtColor,
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
    final profile = ref.watch(userProfileProvider);

    final now = DateTime.now();
    final monthBudgets = allBudgets.where((b) =>
        b.month.year == now.year && b.month.month == now.month).toList();

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
          return expense.splitAmong.contains(userMemberName) ? sum + share : sum;
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
    final lentCount = debts.where((d) => !d.isSettled && d.type == DebtType.lent).length;
    final borrowedCount = debts.where((d) => !d.isSettled && d.type == DebtType.borrowed).length;

    // Goals totals
    final activeGoals = goals.where((g) => !g.isCompleted).toList();
    final totalGoalTarget = activeGoals.fold<double>(0, (sum, g) => sum + g.targetAmount);
    final totalGoalSaved = activeGoals.fold<double>(0, (sum, g) => sum + g.currentAmount);
    final goalPercentage = totalGoalTarget > 0 ? (totalGoalSaved / totalGoalTarget) : 0.0;

    // Budget totals
    final totalBudget = monthBudgets.fold<double>(0, (sum, b) => sum + b.amount);
    final totalBudgetSpent = monthBudgets.fold<double>(0, (sum, b) => sum + b.spent);
    final remainingBudget = (totalBudget - totalBudgetSpent).clamp(0.0, double.infinity);
    final budgetProgress = totalBudget > 0 ? (totalBudgetSpent / totalBudget) : 0.0;

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
                        onPageChanged: (idx) => setState(() => _leftPageIndex = idx),
                        children: [
                          _accountsCardContent(context, accounts, totalBalance, cashTotal, onlineTotal, currency, hideAmounts, toggleReveal, primary),
                          _splitExpensesCardContent(context, splitGroups, totalSplitSpent, yourSplitShare, netOwedAmount, currency, hideAmounts, toggleReveal, primary),
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
                        onPageChanged: (idx) => setState(() => _rightPageIndex = idx),
                        children: [
                          _debtsCardContent(context, lent, borrowed, activeDebts, lentCount, borrowedCount, currency, hideAmounts, toggleReveal, primary),
                          _goalsCardContent(context, goals, totalGoalTarget, totalGoalSaved, goalPercentage, currency, hideAmounts, toggleReveal, primary),
                          _budgetsCardContent(context, monthBudgets, totalBudget, totalBudgetSpent, remainingBudget, budgetProgress, currency, hideAmounts, toggleReveal, primary),
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
            width: 28, height: 28,
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
              child: Icon(Icons.chevron_right_rounded,
                  size: 16, color: primary),
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
                      : formatAmount(currency, totalBalance,
                          hide: hideAmounts),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: accounts.isEmpty ? 12 : 18,
                    fontWeight: accounts.isEmpty
                        ? FontWeight.w600
                        : FontWeight.w800,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
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
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.45),
          ),
        ),
        if (accounts.isNotEmpty) ...[
          const SizedBox(height: 6),
          _accountMiniLine(context, context.t('cash'),
              cashTotal, currency, hideAmounts, toggleReveal),
          const SizedBox(height: 3),
          _accountMiniLine(context, context.t('online'),
              onlineTotal, currency, hideAmounts, toggleReveal),
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
            width: 28, height: 28,
            decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.call_split_rounded,
                color: Colors.blue, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
                bn ? 'স্প্লিট খরচ' : 'Split Expenses',
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
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.45),
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
                : (isOwed ? (bn ? 'পাবেন' : 'To Receive') : (bn ? 'দেবেন' : 'To Pay')),
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
        _cardHeader2(
            context,
            context.t('debts'),
            Icons.handshake_rounded,
            AppColors.warning,
            () => context.push('/debts')),
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
              : context.t('due_count',
                  params: {'count': activeDebts.toString()}),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.45),
          ),
        ),
        if (lent > 0 || borrowed > 0) ...[
          const SizedBox(height: 6),
          _debtMiniLine(context, context.t('to_receive'),
              lent, AppColors.success, currency, hideAmounts,
              lentCount),
          const SizedBox(height: 3),
          _debtMiniLine(context, context.t('to_pay'),
              borrowed, AppColors.error, currency, hideAmounts,
              borrowedCount),
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
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.45),
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
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.45),
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
            color: isActive
                ? activeColor
                : activeColor.withValues(alpha: 0.25),
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
          width: 6, height: 6,
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
          width: 6, height: 6,
          decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
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
          width: 6, height: 6,
          decoration: const BoxDecoration(color: Colors.purpleAccent, shape: BoxShape.circle),
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
          width: 6, height: 6,
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(context.t('transfer_funds'),
                  style: AppTextStyles.h5),
              const SizedBox(height: 16),
              // From account
              Text('From',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45))),
              const SizedBox(height: 8),
              _buildAccountChips(
                  ctx, accounts, fromAccount, currency,
                  (a) => setModalState(() {
                        fromAccount = a;
                        if (toAccount == a) toAccount = null;
                      })),
              const SizedBox(height: 14),
              // To account
              Text('To',
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
                          _showTransfer(
                              fromAccount!, toAccount!, currency);
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
                      const Icon(Icons.swap_horiz_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(fromAccount != null && toAccount != null
                          ? '${fromAccount!.name}  →  ${toAccount!.name}'
                          : context.t('select')),
                    ],
                  ),
                ),
              ),
            ],
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
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? primary.withValues(alpha: 0.12)
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? primary
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(a.icon ?? '💳',
                        style: const TextStyle(fontSize: 14)),
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
                  '$currency${a.balance.toStringAsFixed(0)}',
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

  Widget _cardHeader2(BuildContext context, String title, IconData icon,
      Color iconColor, VoidCallback onTap) {
    return Row(children: [
      Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 14)),
      const SizedBox(width: 8),
      Expanded(
          child: Text(title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface))),
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
            onTap: onTap,
            child: Icon(Icons.chevron_right_rounded,
                size: 16,
                color: iconColor)),
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
          width: 6, height: 6,
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
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.5),
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

  void _showTransfer(dynamic from, dynamic to, String currency) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 12),
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
                  final amount = double.tryParse(ctrl.text.trim()) ?? 0;
                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(context.t('enter_valid_amount'))));
                    return;
                  }
                  if (amount > from.balance) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(context.t('insufficient_balance'))));
                    return;
                  }
                  await ref
                      .read(accountsProvider.notifier)
                      .updateBalance(from.id, from.balance - amount);
                  await ref
                      .read(accountsProvider.notifier)
                      .updateBalance(to.id, to.balance + amount);
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
    );
  }

  int _alertCount(DashboardSummary summary, List budgets, List debts) {
    final accounts = ref.read(accountsProvider);
    int n = 0;
    if (accounts.isNotEmpty && summary.totalBalance < 0) {
      n++;
    }
    if (budgets.any((b) => b.amount > 0 && b.spent / b.amount >= 0.9)) {
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
}
