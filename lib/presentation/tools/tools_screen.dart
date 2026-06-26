// lib/presentation/tools/tools_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/l10n/app_l10n.dart';
import '../providers/app_providers.dart';
import '../../data/models/debt_model.dart';

class ToolsScreen extends ConsumerStatefulWidget {
  const ToolsScreen({super.key});

  @override
  ConsumerState<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends ConsumerState<ToolsScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  static const List<int> _delays = [0, 80, 160, 240, 320, 400, 480, 560, 640, 720, 800];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _fadeAnims = _delays.map((ms) {
      final s = (ms / 1100).clamp(0.0, 1.0);
      final e = ((ms + 380) / 1100).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(s, e, curve: Curves.easeOut),
      );
    }).toList();

    _slideAnims = _delays.map((ms) {
      final s = (ms / 1100).clamp(0.0, 1.0);
      final e = ((ms + 380) / 1100).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(s, e, curve: Curves.easeOutCubic),
      ));
    }).toList();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Widget _anim({required int index, required Widget child}) {
    return FadeTransition(
      opacity: _fadeAnims[index],
      child: SlideTransition(position: _slideAnims[index], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final settings = ref.watch(settingsProvider);
    final currency = (settings['currency'] as String?) ?? '৳';
    final splitGroups = ref.watch(splitGroupsProvider);

    final budgets = ref.watch(budgetsProvider.notifier).getBudgetsForCurrentMonth();
    final goals = ref.watch(goalsProvider);
    final debts = ref.watch(debtsProvider);
    final investments = ref.watch(investmentsProvider);
    final assets = ref.watch(assetsProvider);
    final now = DateTime.now();

    // Budget
    final totalBudget = budgets.fold<double>(0, (s, b) => s + b.amount);
    final totalSpent = budgets.fold<double>(0, (s, b) => s + b.spent);
    final budgetRemaining = (totalBudget - totalSpent).clamp(0.0, double.infinity);
    final budgetProgress = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final budgetColor = budgetProgress >= 0.9
        ? AppColors.error
        : budgetProgress >= 0.7
            ? AppColors.warning
            : AppColors.success;

    // Goals
    final activeGoals = goals.where((g) => !g.isCompleted).toList();
    final totalGoalTarget = activeGoals.fold<double>(0, (s, g) => s + g.targetAmount);
    final totalGoalSaved = activeGoals.fold<double>(0, (s, g) => s + g.currentAmount);
    final overallGoalProgress = totalGoalTarget > 0
        ? (totalGoalSaved / totalGoalTarget).clamp(0.0, 1.0)
        : 0.0;

    // Debts
    double lent = 0, borrowed = 0;
    int dueSoon = 0;
    for (final d in debts) {
      if (d.isSettled) continue;
      final rem = (d.amount - d.paidAmount).clamp(0.0, d.amount);
      if (d.type == DebtType.lent) {
        lent += rem;
      } else {
        borrowed += rem;
      }
      if (d.dueDate != null && d.dueDate!.isBefore(now.add(const Duration(days: 7)))) {
        dueSoon++;
      }
    }

    // Investments
    final totalInvested = investments.fold<double>(0, (s, i) => s + i.investedAmount);
    final totalCurrent = investments.fold<double>(0, (s, i) => s + i.currentValue);
    final returns = totalCurrent - totalInvested;

    // Assets
    final totalAssetValue = assets.fold<double>(0, (s, a) => s + a.currentValue);

    // Subscriptions
    final allTransactions = ref.watch(transactionsProvider);
    final subCount = allTransactions.where((t) => t.isRecurring && t.recurringType != null).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header with tab-style design
            SliverToBoxAdapter(
              child: _anim(index: 0, child: _buildHeader(context, isDark, primary)),
            ),

            // ── Horizontal Quick Stats Strip
            SliverToBoxAdapter(
              child: _anim(
                index: 1,
                child: _buildQuickStatsStrip(
                  context, isDark, primary, currency,
                  totalBudget, totalSpent, budgetRemaining, budgetProgress, budgetColor,
                  totalGoalSaved, totalGoalTarget, overallGoalProgress,
                  activeGoals.length, lent, borrowed, subCount, splitGroups.length,
                ),
              ),
            ),

            // ── Budget Card (full width, detailed)
            SliverToBoxAdapter(
              child: _anim(
                index: 2,
                child: _buildBudgetCard(
                  context, isDark, primary, currency,
                  budgetProgress, budgetColor, budgetRemaining, totalBudget, totalSpent, budgets,
                ),
              ),
            ),

            // ── Goals Card (full width with individual goal bars)
            SliverToBoxAdapter(
              child: _anim(
                index: 3,
                child: _buildGoalsCard(
                  context, isDark, primary, currency,
                  overallGoalProgress, totalGoalSaved, totalGoalTarget, activeGoals,
                ),
              ),
            ),

            // ── Wealth Overview (Debts, Investments, Assets as a vertical list)
            SliverToBoxAdapter(
              child: _anim(
                index: 4,
                child: _buildWealthSection(
                  context, isDark, primary, currency,
                  lent, borrowed, dueSoon,
                  totalInvested, returns,
                  totalAssetValue, assets.isEmpty,
                ),
              ),
            ),

            // ── Quick Actions (horizontal scrollable chips)
            SliverToBoxAdapter(
              child: _anim(
                index: 5,
                child: _buildQuickActions(context, isDark, primary, subCount),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool isDark, Color primary) {
    final now = DateTime.now();
    final month = DateFormat('MMMM yyyy').format(now);
    final day = DateFormat('EEEE, d').format(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Row(children: [
        // Left: Planning icon + title
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primary,
                Color.lerp(primary, const Color(0xFF059669), 0.5)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              context.t('planning'),
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.6,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              '$day · $month',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ]),
        ),
        _iconBtn(context, Icons.note_alt_outlined, isDark, () => context.push('/notes'), tip: context.t('notes')),
      ]),
    );
  }

  Widget _iconBtn(BuildContext ctx, IconData icon, bool isDark, VoidCallback onTap, {String? tip}) {
    final w = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Icon(icon, size: 20, color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.65)),
        ),
      ),
    );
    return tip != null ? Tooltip(message: tip, child: w) : w;
  }

  // ── Quick Stats Strip ──────────────────────────────────────────────────────
  Widget _buildQuickStatsStrip(
    BuildContext context, bool isDark, Color primary, String currency,
    double totalBudget, double totalSpent, double budgetRemaining,
    double budgetProgress, Color budgetColor,
    double totalGoalSaved, double totalGoalTarget, double overallGoalProgress,
    int activeGoalCount, double lent, double borrowed, int subCount,
    int activeSplitGroupsCount,
  ) {
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        children: [
          _quickStatChip(
            context, isDark,
            icon: Icons.category_rounded,
            label: context.t('manage_categories'),
            value: '–',
            subtitle: context.t('customize_categories'),
            accentColor: const Color(0xFFF59E0B),
            onTap: () => context.push('/categories'),
          ),
          const SizedBox(width: 10),
          _quickStatChip(
            context, isDark,
            icon: Icons.group_work_rounded,
            label: context.t('split_expenses'),
            value: activeSplitGroupsCount > 0 ? '$activeSplitGroupsCount' : '–',
            subtitle: activeSplitGroupsCount > 0
                ? (Localizations.localeOf(context).languageCode == 'bn'
                    ? '$activeSplitGroupsCountটি সক্রিয় গ্রুপ'
                    : '$activeSplitGroupsCount active group${activeSplitGroupsCount > 1 ? 's' : ''}')
                : context.t('split_group_empty'),
            accentColor: AppColors.primary,
            onTap: () => context.push('/split-expenses'),
          ),
         const SizedBox(width: 10),
          _quickStatChip(
            context, isDark,
            icon: Icons.calendar_today_rounded,
            label: context.t('subscription_calendar'),
            value: subCount > 0 ? '$subCount' : '–',
            subtitle: subCount > 0 ? '$subCount active' : context.t('track_recurring'),
            accentColor: const Color(0xFF3B82F6),
            onTap: () => context.push('/subscriptions'),
          ),
          const SizedBox(width: 10),
          _quickStatChip(
            context, isDark,
            icon: Icons.handshake_rounded,
            label: context.t('debts_loans'),
            value: (lent + borrowed) > 0 ? '$currency${_fmt(lent + borrowed)}' : '–',
            subtitle: (lent + borrowed) > 0 ? context.t('net_balance') : 'No debts',
            accentColor: AppColors.warning,
          ),
          const SizedBox(width: 10),
          _quickStatChip(
            context, isDark,
            icon: Icons.flag_rounded,
            label: context.t('goals'),
            value: activeGoalCount > 0 ? '$currency${_fmt(totalGoalSaved)}' : '–',
            subtitle: activeGoalCount > 0 ? '$activeGoalCount ${context.t('active_goals_short')}' : context.t('no_goals_yet'),
            accentColor: const Color(0xFF8B5CF6),
            progress: activeGoalCount > 0 ? overallGoalProgress : null,
          ),

          const SizedBox(width: 10),
          _quickStatChip(
            context, isDark,
            icon: Icons.account_balance_wallet_rounded,
            label: context.t('budget'),
            value: totalBudget > 0 ? '$currency${_fmt(budgetRemaining)}' : '–',
            subtitle: totalBudget > 0 ? '${(budgetProgress * 100).toStringAsFixed(0)}% ${context.t('spent')}' : context.t('no_budget_set'),
            accentColor: budgetColor,
            progress: totalBudget > 0 ? budgetProgress : null,
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _quickStatChip(
    BuildContext context, bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color accentColor,
    double? progress,
    VoidCallback? onTap,
  }) {
    final chip = Container(
      width: 155,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.2 : 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (progress != null)
                SizedBox(
                  width: 28, height: 28,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2.5,
                    backgroundColor: accentColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
              Icon(icon, color: accentColor, size: progress != null ? 12 : 16),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45), letterSpacing: 0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5, height: 1.3), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(subtitle, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500, color: accentColor.withValues(alpha: 0.8), height: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ]),
    );
    return onTap != null ? GestureDetector(onTap: onTap, child: chip) : chip;
  }

  // ── Budget Card ────────────────────────────────────────────────────────────
  Widget _buildBudgetCard(
    BuildContext context, bool isDark, Color primary, String currency,
    double budgetProgress, Color budgetColor, double budgetRemaining,
    double totalBudget, double totalSpent, List budgets,
  ) {
    return GestureDetector(
      onTap: () => context.push('/budget'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Top row: icon + title + badge + arrow
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [budgetColor, budgetColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.pie_chart_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.t('monthly_budget'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.2)),
                if (totalBudget > 0)
                  Text(
                    '${(budgetProgress * 100).toStringAsFixed(0)}% ${context.t('spent')} · $currency${_fmt(totalSpent)} ${context.t('of')} $currency${_fmt(totalBudget)}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                  ),
              ]),
            ),
            if (totalBudget > 0)
              _statusTag(budgetProgress, budgetColor),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25)),
          ]),

          if (totalBudget > 0) ...[
            const SizedBox(height: 16),
            // Main remaining amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currency${_fmt(budgetRemaining)}',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: budgetColor,
                    letterSpacing: -1.5,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    context.t('remaining'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Segmented progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Stack(children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: budgetColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: budgetProgress,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [budgetColor.withValues(alpha: 0.7), budgetColor],
                      ),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [BoxShadow(color: budgetColor.withValues(alpha: 0.4), blurRadius: 6)],
                    ),
                  ),
                ),
              ]),
            ),
            // Category mini bars
            if (budgets.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...budgets.take(3).map((b) {
                final p = b.amount > 0 ? (b.spent / b.amount).clamp(0.0, 1.0) : 0.0;
                final bColor = p >= 0.9 ? AppColors.error : p >= 0.7 ? AppColors.warning : AppColors.success;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        '${b.categoryId}',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: p,
                          minHeight: 4,
                          backgroundColor: bColor.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(bColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(p * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: bColor)),
                  ]),
                );
              }),
            ],
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.add_circle_outline_rounded, size: 16, color: primary.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Text(context.t('no_budget_set'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primary.withValues(alpha: 0.7))),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _statusTag(double progress, Color color) {
    final label = progress >= 0.9 ? 'Critical' : progress >= 0.7 ? 'Warning' : 'On Track';
    final icon = progress >= 0.9 ? Icons.warning_rounded : progress >= 0.7 ? Icons.bolt_rounded : Icons.check_circle_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  // ── Goals Card ─────────────────────────────────────────────────────────────
  Widget _buildGoalsCard(
    BuildContext context, bool isDark, Color primary, String currency,
    double overallGoalProgress, double totalGoalSaved, double totalGoalTarget, List activeGoals,
  ) {
    const goalPurple = Color(0xFF8B5CF6);

    return GestureDetector(
      onTap: () => context.push('/goals'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Top row
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.flag_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.t('savings_goals'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.2)),
                if (activeGoals.isNotEmpty)
                  Text(
                    '${activeGoals.length} ${context.t('active_goals_short')} · ${(overallGoalProgress * 100).toStringAsFixed(0)}% ${context.t('saved')}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                  ),
              ]),
            ),
            if (activeGoals.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: goalPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$currency${_fmt(totalGoalSaved)}',
                  style: const TextStyle(color: goalPurple, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25)),
          ]),

          if (activeGoals.isNotEmpty) ...[
            const SizedBox(height: 16),
            // Overall progress bar
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Stack(children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: goalPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: overallGoalProgress,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [BoxShadow(color: goalPurple.withValues(alpha: 0.4), blurRadius: 6)],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(overallGoalProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: goalPurple, fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ]),
            const SizedBox(height: 10),
            // Individual goals
            ...activeGoals.take(3).map((g) {
              final gp = g.targetAmount > 0 ? (g.currentAmount / g.targetAmount).clamp(0.0, 1.0) : 0.0;
              final gColor = _goalColor(activeGoals.indexOf(g));
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: gColor.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: gColor.withValues(alpha: 0.1)),
                ),
                child: Row(children: [
                  Text(g.icon ?? '🎯', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        g.name,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: gp,
                          minHeight: 4,
                          backgroundColor: gColor.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(gColor),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${(gp * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: gColor)),
                    Text('$currency${_fmt(g.currentAmount)}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
                  ]),
                ]),
              );
            }),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: goalPurple.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.add_circle_outline_rounded, size: 16, color: goalPurple.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Text(context.t('no_goals_yet'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: goalPurple.withValues(alpha: 0.7))),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  // ── Wealth Section ─────────────────────────────────────────────────────────
  Widget _buildWealthSection(
    BuildContext context, bool isDark, Color primary, String currency,
    double lent, double borrowed, int dueSoon,
    double totalInvested, double returns,
    double totalAssetValue, bool assetsEmpty,
  ) {
    final isPos = returns >= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Section title
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.assessment_rounded, size: 14, color: primary),
          ),
          const SizedBox(width: 8),
          Text(
            'Wealth Overview',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              letterSpacing: -0.1,
            ),
          ),
        ]),
        const SizedBox(height: 14),

        // Debts row
        _wealthRow(
          context, isDark,
          icon: Icons.handshake_rounded,
          iconColor: AppColors.warning,
          title: context.t('debts_loans'),
          value: '$currency${_fmt(lent + borrowed)}',
          subtitle: dueSoon > 0 ? context.t('due_count', params: {'count': dueSoon.toString()}) : context.t('net_balance'),
          subtitleColor: dueSoon > 0 ? AppColors.warning : null,
          showBadge: dueSoon > 0,
          onTap: () => context.push('/debts'),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06), height: 1),
        ),

        // Investments row
        _wealthRow(
          context, isDark,
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFF6366F1),
          title: context.t('investments'),
          value: totalInvested > 0 ? '$currency${_fmt(totalInvested)}' : '–',
          subtitle: totalInvested > 0
              ? '${isPos ? '+' : ''}$currency${_fmt(returns.abs())}'
              : context.t('add_first_investment'),
          subtitleColor: totalInvested > 0 ? (isPos ? AppColors.success : AppColors.error) : null,
          onTap: () => context.push('/investments'),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06), height: 1),
        ),

        // Assets row
        _wealthRow(
          context, isDark,
          icon: Icons.inventory_2_rounded,
          iconColor: const Color(0xFF059669),
          title: context.t('assets_title'),
          value: assetsEmpty ? '–' : '$currency${_fmt(totalAssetValue)}',
          subtitle: assetsEmpty ? context.t('add_first_asset') : context.t('total_asset_value'),
          onTap: () => context.push('/assets'),
        ),
      ]),
    );
  }

  Widget _wealthRow(
    BuildContext context, bool isDark, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    Color? subtitleColor,
    bool showBadge = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                Center(child: Icon(icon, color: iconColor, size: 17)),
                if (showBadge)
                  Positioned(
                    top: 2, right: 2,
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
              Text(subtitle, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: subtitleColor ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
            ]),
          ),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
        ]),
      ),
    );
  }

  // ── Quick Actions ──────────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context, bool isDark, Color primary, int subCount) {
    final tools = [
      _ToolItem(
        icon: Icons.calculate_rounded,
        color: const Color(0xFF7C3AED),
        label: context.t('emi_calculator'),
        sub: context.t('calculate_emi'),
        route: '/emi-calculator',
      ),
      _ToolItem(
        icon: Icons.description_rounded,
        color: const Color(0xFF10B981),
        label: context.t('reports_export'),
        sub: context.t('download_reports'),
        route: '/reports',
      ),
      _ToolItem(
        icon: Icons.note_alt_rounded,
        color: const Color(0xFFEC4899),
        label: context.t('notes'),
        sub: context.t('personal_notes'),
        route: '/notes',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.build_rounded, size: 14, color: primary),
            ),
            const SizedBox(width: 9),
            Text(
              context.t('tools_utilities'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                letterSpacing: -0.1,
              ),
            ),
          ]),
        ),
        // Horizontal scrollable tool cards
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            itemCount: tools.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _buildToolCard(context, isDark, tools[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildToolCard(BuildContext context, bool isDark, _ToolItem tool) {
    return GestureDetector(
      onTap: () => context.push(tool.route),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: tool.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tool.icon, color: tool.color, size: 18),
              ),
              if (tool.badge != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tool.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(tool.badge!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              ],
            ]),
            const Spacer(),
            Text(
              tool.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.1,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              tool.sub,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Color _goalColor(int i) {
    const colors = [Color(0xFF8B5CF6), Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEC4899)];
    return colors[i % colors.length];
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _ToolItem {
  final IconData icon;
  final Color color;
  final String label;
  final String sub;
  final String route;
  final String? badge;

  const _ToolItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.sub,
    required this.route,
    this.badge,
  });
}
