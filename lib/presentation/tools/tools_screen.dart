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
  late AnimationController _animCtrl;

  // Pre-created animations to avoid CurvedAnimation leak in build().
  static const List<int> _animDelays = [0, 60, 130, 200];
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _fadeAnims = _animDelays.map((ms) {
      final s = (ms / 700).clamp(0.0, 1.0);
      final e = ((ms + 260) / 700).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _animCtrl, curve: Interval(s, e, curve: Curves.easeOut));
    }).toList();
    _slideAnims = _animDelays.map((ms) {
      final s = (ms / 700).clamp(0.0, 1.0);
      final e = ((ms + 260) / 700).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final settings = ref.watch(settingsProvider);
    final currency = (settings['currency'] as String?) ?? '৳';

    final budgets =
        ref.watch(budgetsProvider.notifier).getBudgetsForCurrentMonth();
    final goals = ref.watch(goalsProvider);
    final debts = ref.watch(debtsProvider);
    final now = DateTime.now();

    // Budget data
    final totalBudget = budgets.fold<double>(0, (s, b) => s + b.amount);
    final totalSpent = budgets.fold<double>(0, (s, b) => s + b.spent);
    final budgetRemaining =
        (totalBudget - totalSpent).clamp(0.0, double.infinity);
    final budgetProgress =
        totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final budgetColor = budgetProgress >= 0.9
        ? AppColors.error
        : budgetProgress >= 0.7
            ? AppColors.warning
            : AppColors.success;

    // Goals data
    final activeGoals = goals.where((g) => !g.isCompleted).toList();
    final totalGoalTarget =
        activeGoals.fold<double>(0, (s, g) => s + g.targetAmount);
    final totalGoalSaved =
        activeGoals.fold<double>(0, (s, g) => s + g.currentAmount);
    final overallGoalProgress = totalGoalTarget > 0
        ? (totalGoalSaved / totalGoalTarget).clamp(0.0, 1.0)
        : 0.0;

    // Debts
    double lent = 0, borrowed = 0;
    int dueSoon = 0;
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
      if (d.dueDate != null &&
          d.dueDate!.isBefore(now.add(const Duration(days: 7)))) {
        dueSoon++;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _anim(index: 0, child: _header(context, isDark)),
            ),

            // ── BUDGET — main hero ────────────────────────────────────
            SliverToBoxAdapter(
              child: _anim(
                index: 1,
                child: _budgetHero(
                    context,
                    currency,
                    totalBudget,
                    totalSpent,
                    budgetRemaining,
                    budgetProgress,
                    budgetColor,
                    budgets,
                    isDark,
                    primary),
              ),
            ),

            // ── GOALS — second hero ───────────────────────────────────
            SliverToBoxAdapter(
              child: _anim(
                index: 2,
                child: _goalsHero(
                    context,
                    currency,
                    activeGoals,
                    totalGoalTarget,
                    totalGoalSaved,
                    overallGoalProgress,
                    isDark),
              ),
            ),

            // ── Debts strip ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: _anim(
                index: 3,
                child: _debtStrip(
                    context, currency, lent, borrowed, dueSoon, isDark),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _header(BuildContext context, bool isDark) {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.t('planning'),
              style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.4,
                  color: Theme.of(context).colorScheme.onSurface)),
          Text(DateFormat('MMMM yyyy').format(now),
              style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                  fontSize: 12)),
        ])),
        _hBtn(context, Icons.calculate_rounded, isDark,
            () => context.push('/calculator'),
            tip: context.t('calculator')),
        const SizedBox(width: 8),
        _hBtn(context, Icons.note_alt_rounded, isDark,
            () => context.push('/notes'),
            tip: context.t('notes')),
      ]),
    );
  }

  Widget _hBtn(BuildContext ctx, IconData icon, bool isDark, VoidCallback onTap,
      {String? tip}) {
    final w = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(13)),
          child: Icon(icon,
              size: 20,
              color:
                  Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6))),
    );
    return tip != null ? Tooltip(message: tip, child: w) : w;
  }

  // ── Budget Hero ───────────────────────────────────────────────────────────
  Widget _budgetHero(
    BuildContext context,
    String currency,
    double totalBudget,
    double totalSpent,
    double budgetRemaining,
    double budgetProgress,
    Color budgetColor,
    List budgets,
    bool isDark,
    Color primary,
  ) {
    final hasData = totalBudget > 0;

    return GestureDetector(
      onTap: () => context.push('/budget'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasData
                ? [
                    budgetColor,
                    Color.lerp(
                        budgetColor,
                        budgetColor == AppColors.error
                            ? Colors.red.shade900
                            : budgetColor == AppColors.warning
                                ? Colors.orange.shade800
                                : Colors.teal.shade800,
                        0.5)!,
                  ]
                : [primary, Color.lerp(primary, Colors.indigo.shade800, 0.5)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (hasData ? budgetColor : primary).withValues(alpha: 0.32),
              blurRadius: 20,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(children: [
          // decorative circles
          Positioned(
              top: -35,
              right: -25,
              child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06)))),
          Positioned(
              bottom: -20,
              left: -10,
              child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04)))),

          Padding(
            padding: const EdgeInsets.all(22),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Top row
              Row(children: [
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.pie_chart_rounded,
                          color: Colors.white, size: 13),
                      const SizedBox(width: 5),
                      Text(context.t('monthly_budget'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ])),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                      hasData
                          ? context.t('used_percent', params: {
                              'value':
                                  (budgetProgress * 100).toStringAsFixed(0)
                            })
                          : context.t('tap_to_set_up'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ]),

              const SizedBox(height: 20),

              if (!hasData) ...[
                // Empty state
                Row(children: [
                  const Icon(Icons.add_circle_outline_rounded,
                      color: Colors.white70, size: 20),
                  const SizedBox(width: 10),
                  Text(context.t('no_budget_set'),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                ]),
                const SizedBox(height: 8),
                Text(context.t('set_budget_track'),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12)),
              ] else ...[
                // Main numbers
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.t('remaining'),
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 3),
                        Text('$currency${_fmt(budgetRemaining)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.5,
                                height: 1.0)),
                      ]),
                  const Spacer(),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(context.t('budget'),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 10)),
                    Text('$currency${_fmt(totalBudget)}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(context.t('spent'),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 10)),
                    Text('$currency${_fmt(totalSpent)}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ]),
                ]),

                const SizedBox(height: 16),

                // Progress bar
                ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: budgetProgress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    )),

                const SizedBox(height: 16),

                // Per-budget chips (top 3)
                Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: budgets.take(3).map<Widget>((b) {
                      final p = b.amount > 0
                          ? (b.spent / b.amount).clamp(0.0, 1.0)
                          : 0.0;
                      final bColor = p >= 0.9
                          ? AppColors.error
                          : p >= 0.7
                              ? AppColors.warning
                              : Colors.white;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                  color: bColor, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text(b.categoryId,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Text('${(p * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 10)),
                        ]),
                      );
                    }).toList()),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Goals Hero ────────────────────────────────────────────────────────────
  Widget _goalsHero(
    BuildContext context,
    String currency,
    List activeGoals,
    double totalTarget,
    double totalSaved,
    double overallProgress,
    bool isDark,
  ) {
    final hasGoals = activeGoals.isNotEmpty;
    const goalColor = Color(0xFF8B5CF6);
    final lang = Localizations.localeOf(context).languageCode;
    final pluralSuffix =
        activeGoals.length > 1 && lang == 'en' ? 's' : '';

    return GestureDetector(
      onTap: () => context.push('/goals'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: hasGoals
                  ? goalColor.withValues(alpha: 0.25)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
                color: hasGoals
                    ? goalColor.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: goalColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.flag_rounded, color: goalColor, size: 20)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(context.t('savings_goals'),
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.2)),
                  Text(
                      hasGoals
                          ? context.t('active_goal_count', params: {
                              'count': activeGoals.length.toString(),
                              'suffix': pluralSuffix,
                            })
                          : context.t('no_goals_yet'),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.45))),
                ])),
            if (hasGoals)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: goalColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${(overallProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        color: goalColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              )
            else
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: goalColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.add_rounded, color: goalColor, size: 14),
                    const SizedBox(width: 3),
                    Text(context.t('add_goal'),
                        style: const TextStyle(
                            color: goalColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ])),
          ]),

          if (hasGoals) ...[
            const SizedBox(height: 16),

            // Overall progress bar
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.t('overall_progress'),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.45),
                                  fontWeight: FontWeight.w500)),
                          Text(
                              '$currency${_fmt(totalSaved)} / $currency${_fmt(totalTarget)}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: goalColor)),
                        ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: overallProgress,
                          minHeight: 6,
                          backgroundColor: goalColor.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(goalColor),
                        )),
                  ])),
            ]),

            const SizedBox(height: 14),

            // Individual goals (max 3)
            ...activeGoals.take(3).map((g) {
              final gp = g.targetAmount > 0
                  ? (g.currentAmount / g.targetAmount).clamp(0.0, 1.0)
                  : 0.0;
              final gColor = _goalColor(activeGoals.indexOf(g));
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: gColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Center(
                          child: Text(g.icon ?? '🎯',
                              style: const TextStyle(fontSize: 16)))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(g.name,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                        Text('$currency${_fmt(g.currentAmount)}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: gColor)),
                      ]),
                      const SizedBox(height: 4),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: gp,
                            minHeight: 4,
                            backgroundColor: gColor.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(gColor),
                          )),
                    ],
                  )),
                  const SizedBox(width: 10),
                  Text('${(gp * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4))),
                ]),
              );
            }),

            if (activeGoals.length > 3)
              Center(
                  child: Text(
                      context.t('more_goals', params: {
                        'count': (activeGoals.length - 3).toString(),
                      }),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: goalColor))),
          ],
        ]),
      ),
    );
  }

  // ── Debt strip ────────────────────────────────────────────────────────────
  Widget _debtStrip(BuildContext context, String currency, double lent,
      double borrowed, int dueSoon, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/debts'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: dueSoon > 0
                  ? AppColors.warning.withValues(alpha: 0.35)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.handshake_rounded,
                  color: AppColors.warning, size: 19)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(context.t('debts_loans'),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(
                    '${context.t('to_receive_short')} $currency${_fmt(lent)}  •  ${context.t('to_pay_short')} $currency${_fmt(borrowed)}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.45))),
              ])),
          if (dueSoon > 0)
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                    context.t('due_count',
                        params: {'count': dueSoon.toString()}),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning))),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded,
              size: 18,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3)),
        ]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Color _goalColor(int i) {
    const colors = [
      Color(0xFF8B5CF6),
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
    ];
    return colors[i % colors.length];
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
