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

  // Pre-created animations to avoid creating new CurvedAnimation objects
  // on every build() call — which leaks InheritedWidget dependents and
  // causes '_dependents.isEmpty' assertion failures.
  static const List<int> _animDelays = [0, 60, 130, 200, 270];
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
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

  // â”€â”€ AppBar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _appBar(BuildContext ctx, Color primary, int alertCount,
      bool hideAmounts, bool isDark) {
    final profile = ref.watch(userProfileProvider);
    final fullName = (profile['fullName'] ?? '').trim();
    final photoBase64 = (profile['photoBase64'] ?? '').trim();
    final profileImage = _resolveProfileImage(photoBase64);
    final initials = fullName.isEmpty
        ? '?'
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
            Text(fullName.isEmpty ? context.t('dashboard') : fullName,
                style: AppTextStyles.h2.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Theme.of(ctx).colorScheme.onSurface)),
          ],
        )),
        if (hideAmounts) ...[
          _navBtn(
              ctx,
              _revealAmounts
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              isDark,
              () => setState(() => _revealAmounts = !_revealAmounts)),
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
                  onTap: toggleReveal,
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

  // â”€â”€ Accounts + Debt Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _accountsDebtRow(
      BuildContext context,
      List<AccountModel> accounts,
      List debts,
      String currency,
      bool hideAmounts,
      VoidCallback toggleReveal,
      bool isDark,
      Color primary) {
    final totalBalance = accounts.fold<double>(0, (sum, a) => sum + a.balance);
    AccountModel? cash;
    AccountModel? online;
    for (final a in accounts) {
      if (a.id == 'acc_cash') cash = a;
      if (a.id == 'acc_online') online = a;
    }
    double lent = 0, borrowed = 0;
    for (final d in debts) {
      if (d.isSettled) {
        continue;
      }
      final rem = (d.amount - d.paidAmount).clamp(0.0, d.amount);
      if (d.type == DebtType.lent) {
        lent += rem;
      } else {
        borrowed += rem;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Accounts
          Expanded(
            child: InkWell(
              onTap: () => context.push('/accounts'),
              borderRadius: BorderRadius.circular(20),
              child: _surfCard(context, isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardHeader2(
                          context,
                          context.t('accounts'),
                          Icons.account_balance_wallet_rounded,
                          primary,
                          () => context.push('/accounts')),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: toggleReveal,
                        behavior: HitTestBehavior.translucent,
                        child: Text(
                          accounts.isEmpty
                              ? context.t('no_accounts')
                              : formatAmount(currency, totalBalance,
                                  hide: hideAmounts),
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
                      const SizedBox(height: 4),
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
                        if (cash != null)
                          _accountMiniLine(
                            context,
                            context.t('cash'),
                            cash.balance,
                            currency,
                            hideAmounts,
                            toggleReveal,
                          ),
                        if (online != null)
                          _accountMiniLine(
                            context,
                            context.t('online'),
                            online.balance,
                            currency,
                            hideAmounts,
                            toggleReveal,
                          ),
                      ],
                      if (cash != null && online != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () =>
                                _showTransferPicker(cash!, online!, currency),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.swap_horiz_rounded,
                                      size: 12, color: primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    context.t('transfer'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                    ],
                  )),
            ),
          ),

          const SizedBox(width: 12),

          // Debts
          Expanded(
            child: _surfCard(context, isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardHeader2(
                        context,
                        context.t('debts'),
                        Icons.handshake_rounded,
                        AppColors.warning,
                        () => context.push('/debts')),
                    const SizedBox(height: 10),
                    _debtLine(context, context.t('to_receive'), lent,
                        AppColors.success, currency, hideAmounts, toggleReveal),
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Divider(
                            height: 1,
                            color: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.4))),
                    _debtLine(context, context.t('to_pay'), borrowed,
                        AppColors.error, currency, hideAmounts, toggleReveal),
                    const Spacer(),
                  ],
                )),
          ),
        ]),
      ),
    );
  }

  void _showTransferPicker(
      AccountModel cash, AccountModel online, String currency) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded),
                title: Text('${cash.name} -> ${online.name}'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showTransfer(cash, online, currency);
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded),
                title: Text('${online.name} -> ${cash.name}'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showTransfer(online, cash, currency);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
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
      GestureDetector(
          onTap: onTap,
          child: Icon(Icons.chevron_right_rounded,
              size: 16,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3))),
    ]);
  }

  Widget _debtLine(BuildContext context, String label, double amount,
      Color color, String currency, bool hideAmounts, VoidCallback onTap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 10,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4))),
      const SizedBox(height: 3),
      GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.translucent,
          child: Text(formatAmount(currency, amount, hide: hideAmounts),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.3))),
    ]);
  }

  Widget _accountMiniLine(
    BuildContext context,
    String label,
    double amount,
    String currency,
    bool hideAmounts,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
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
      ),
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
          Text('${from.name}  ->  ${to.name}',
              style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5))),
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
    int n = 0;
    if (summary.totalBalance < 0) {
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
    if (h < 12) return context.t('good_morning');
    if (h < 17) return context.t('good_afternoon');
    return context.t('good_evening');
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
