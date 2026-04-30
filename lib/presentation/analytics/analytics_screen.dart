// lib/presentation/analytics/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/amount_mask.dart';
import '../../core/l10n/app_l10n.dart';
import '../providers/app_providers.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  bool _revealAmounts = false;
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Widget _anim({required int ms, required Widget child}) {
    final s = (ms / 800).clamp(0.0, 1.0);
    final e = ((ms + 320) / 800).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: CurvedAnimation(
          parent: _animCtrl, curve: Interval(s, e, curve: Curves.easeOut)),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _animCtrl,
                curve: Interval(s, e, curve: Curves.easeOutCubic))),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analytics = ref.watch(monthlyAnalyticsProvider(DateTime.now()));
    final categories = ref.watch(categoriesProvider);
    final transactions = ref.watch(transactionsProvider);
    final settings = ref.watch(settingsProvider);
    final currency = settings['currency'] ?? '৳';
    final hideAmounts = settings['hideAmounts'] ?? false;
    final effectiveHide = hideAmounts && !_revealAmounts;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    void toggleReveal() {
      if (!hideAmounts) return;
      setState(() => _revealAmounts = !_revealAmounts);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _anim(
                  ms: 0,
                  child: _buildHeader(
                      context,
                      analytics,
                      currency,
                      transactions,
                      effectiveHide,
                      isDark,
                      hideAmounts,
                      toggleReveal,
                      primary)),
            ),
            SliverToBoxAdapter(
              child: _anim(
                  ms: 80,
                  child: _buildSummaryCards(analytics, currency, effectiveHide,
                      toggleReveal, isDark, primary)),
            ),
            SliverToBoxAdapter(
              child: _anim(
                  ms: 160,
                  child: _buildCategoryBreakdown(
                      analytics, categories, isDark, primary)),
            ),
            SliverToBoxAdapter(
              child: _anim(
                  ms: 320,
                  child: _buildLineTrend(
                      analytics, currency, effectiveHide, isDark, primary)),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(
      BuildContext context,
      MonthlyAnalytics analytics,
      String currency,
      List<TransactionModel> transactions,
      bool effectiveHide,
      bool isDark,
      bool hideAmounts,
      VoidCallback toggleReveal,
      Color primary) {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('analytics'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: InkWell(
                    onTap: () => _showCalendarSheet(context, analytics,
                        currency, transactions, effectiveHide, isDark, primary),
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 10, color: primary),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMMM yyyy').format(now),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hideAmounts) ...[
            _iconBtn(
                context,
                _revealAmounts
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                isDark,
                toggleReveal),
            const SizedBox(width: 8),
          ],
          _iconBtn(
            context,
            Icons.tune_rounded,
            isDark,
            () => _showCalendarSheet(
              context,
              analytics,
              currency,
              transactions,
              effectiveHide,
              isDark,
              primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(
      BuildContext context, IconData icon, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Icon(icon,
            size: 20,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.65)),
      ),
    );
  }

  // ── Summary Cards ────────────────────────────────────────────────────────

  Widget _buildSummaryCards(MonthlyAnalytics analytics, String currency,
      bool hideAmounts, VoidCallback toggleReveal, bool isDark, Color primary) {
    final savingsRate = analytics.totalIncome > 0
        ? (analytics.netSavings / analytics.totalIncome * 100)
        : 0.0;
    final rateColor = savingsRate >= 20
        ? AppColors.success
        : savingsRate >= 10
            ? AppColors.warning
            : AppColors.error;
    final isPositiveSavings = analytics.netSavings >= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _modernSummaryCard(
                  context: context,
                  label: context.t('income'),
                  value: formatAmount(currency, analytics.totalIncome,
                      hide: hideAmounts),
                  icon: Icons.arrow_downward_rounded,
                  color: AppColors.success,
                  isDark: isDark,
                  onTap: toggleReveal,
                  gradientColors: [
                    const Color(0xFF10B981),
                    const Color(0xFF34D399)
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _modernSummaryCard(
                  context: context,
                  label: context.t('expense'),
                  value: formatAmount(currency, analytics.totalExpense,
                      hide: hideAmounts),
                  icon: Icons.arrow_upward_rounded,
                  color: AppColors.error,
                  isDark: isDark,
                  onTap: toggleReveal,
                  gradientColors: [
                    const Color(0xFFEF4444),
                    const Color(0xFFF87171)
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _modernSummaryCard(
                  context: context,
                  label: context.t('net_savings'),
                  value: formatAmount(currency, analytics.netSavings.abs(),
                      hide: hideAmounts),
                  icon: isPositiveSavings
                      ? Icons.savings_rounded
                      : Icons.trending_down_rounded,
                  color: isPositiveSavings ? AppColors.info : AppColors.error,
                  isDark: isDark,
                  subtitle: isPositiveSavings ? null : context.t('deficit'),
                  onTap: toggleReveal,
                  gradientColors: isPositiveSavings
                      ? [const Color(0xFF3B82F6), const Color(0xFF60A5FA)]
                      : [const Color(0xFFEF4444), const Color(0xFFF87171)],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _modernSummaryCard(
                  context: context,
                  label: context.t('savings_rate'),
                  value: '${savingsRate.abs().toStringAsFixed(1)}%',
                  icon: Icons.percent_rounded,
                  color: rateColor,
                  isDark: isDark,
                  gradientColors: rateColor == AppColors.success
                      ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                      : rateColor == AppColors.warning
                          ? [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]
                          : [const Color(0xFFEF4444), const Color(0xFFF87171)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modernSummaryCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    required List<Color> gradientColors,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle != null ? '$label · $subtitle' : label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category Breakdown ───────────────────────────────────────────────────

  Widget _buildCategoryBreakdown(MonthlyAnalytics analytics,
      List<CategoryModel> categories, bool isDark, Color primary) {
    final breakdown = analytics.getCategoryBreakdown(TransactionType.expense);
    final categoryMap = {for (final c in categories) c.id: c};
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();
    final highest = top.isEmpty
        ? 1.0
        : top.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final maxY = highest * 1.25;

    return _card(
      context,
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(context, context.t('category_breakdown'),
              Icons.bar_chart_rounded, primary),
          const SizedBox(height: 18),
          if (top.isEmpty)
            _emptyState(context, context.t('no_expense_month'))
          else ...[
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.25),
                      strokeWidth: 0.8,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= top.length) {
                            return const SizedBox.shrink();
                          }
                          final name =
                              categoryMap[top[i].key]?.name ?? top[i].key;
                          final label = name.length > 6
                              ? '${name.substring(0, 6)}.'
                              : name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                )),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < top.length; i++)
                      _makeGroupData(
                          i,
                          top[i].value,
                          AppColors
                              .chartColors[i % AppColors.chartColors.length],
                          maxY),
                  ],
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) =>
                          isDark ? const Color(0xFF1E2A3A) : Colors.white,
                      tooltipBorderRadius: BorderRadius.circular(10),
                      tooltipBorder: BorderSide(
                          color: isDark ? Colors.white12 : Colors.black12),
                      getTooltipItem: (group, _, rod, __) {
                        final i = group.x;
                        if (i < 0 || i >= top.length) return null;
                        final name =
                            categoryMap[top[i].key]?.name ?? top[i].key;
                        final color = AppColors
                            .chartColors[i % AppColors.chartColors.length];
                        return BarTooltipItem(
                            '$name\n${rod.toY.toStringAsFixed(0)}',
                            TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 12));
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (int i = 0; i < top.length; i++)
                  _legendChip(
                    context,
                    categoryMap[top[i].key]?.name ?? top[i].key,
                    AppColors.chartColors[i % AppColors.chartColors.length],
                    isDark,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _legendChip(
      BuildContext context, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color, double maxY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 28,
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.65)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: color.withValues(alpha: 0.07),
          ),
        ),
      ],
    );
  }

  // ── Calendar Heatmap ─────────────────────────────────────────────────────

  Widget _buildCalendarSection(
      MonthlyAnalytics analytics,
      String currency,
      List<TransactionModel> transactions,
      bool hideAmounts,
      bool isDark,
      Color primary) {
    final month = analytics.month;
    final startOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startOffset = startOfMonth.weekday - 1;

    final expenseByDay = <int, double>{};
    for (final t in analytics.transactions) {
      if (t.type == TransactionType.expense) {
        expenseByDay[t.date.day] = (expenseByDay[t.date.day] ?? 0) + t.amount;
      }
    }

    final maxExpense = expenseByDay.isEmpty
        ? 0.0
        : expenseByDay.values.reduce((a, b) => math.max(a, b));

    Color dayColor(double amount) {
      if (amount <= 0 || maxExpense <= 0) {
        return isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04);
      }
      final intensity = (amount / maxExpense).clamp(0.15, 1.0);
      return AppColors.error.withValues(alpha: intensity * 0.9);
    }

    final totalCells = startOffset + daysInMonth;
    final trailing = (7 - (totalCells % 7)) % 7;
    final cells = totalCells + trailing;
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now();

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: weekdays
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.35))),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 1,
            ),
            itemBuilder: (_, index) {
              final dayNumber = index - startOffset + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              final amount = expenseByDay[dayNumber] ?? 0;
              final dayDate = DateTime(month.year, month.month, dayNumber);
              final dayTransactions = transactions
                  .where((t) =>
                      t.date.year == dayDate.year &&
                      t.date.month == dayDate.month &&
                      t.date.day == dayDate.day)
                  .toList();
              final isToday = dayDate.year == today.year &&
                  dayDate.month == today.month &&
                  dayDate.day == today.day;

              return GestureDetector(
                onTap: () => _showDaySheet(
                    context, dayDate, dayTransactions, currency, hideAmounts),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: dayColor(amount),
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: primary, width: 2)
                        : Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.05),
                            width: 0.5),
                    boxShadow: amount > 0
                        ? [
                            BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text('$dayNumber',
                        style: TextStyle(
                          fontWeight:
                              isToday ? FontWeight.w900 : FontWeight.w600,
                          fontSize: 10,
                          color: amount > maxExpense * 0.3
                              ? Colors.white
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: isToday ? 1.0 : 0.6),
                        )),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(context.t('less'),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4))),
              const SizedBox(width: 8),
              ...List.generate(
                  5,
                  (i) => Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error
                              .withValues(alpha: 0.1 + (i * 0.18)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
              const SizedBox(width: 4),
              Text(context.t('more'),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4))),
            ],
          ),
        ],
    );
  }

  void _showDaySheet(BuildContext context, DateTime date,
      List<TransactionModel> dayTx, String currency, bool hideAmounts) {
    final primary = Theme.of(context).colorScheme.primary;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.calendar_today_rounded,
                      color: primary, size: 18),
                ),
                const SizedBox(width: 12),
                Text(DateFormat('EEEE, MMM d, yyyy').format(date),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
              ],
            ),
            const SizedBox(height: 16),
            if (dayTx.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: Column(children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 40,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.2)),
                  const SizedBox(height: 8),
                  Text(context.t('no_transactions'),
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4))),
                ])),
              )
            else
              ...dayTx.take(5).map((t) {
                final isIncome = t.type == TransactionType.income;
                final color = isIncome ? AppColors.success : AppColors.error;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.15)),
                  ),
                  child: Row(children: [
                    Icon(
                        isIncome
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: color,
                        size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(t.categoryId,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13))),
                    Text(
                      hideAmounts
                          ? '••••'
                          : '${isIncome ? '+' : '-'}$currency${t.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ]),
                );
              }),
            if (dayTx.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text('+${dayTx.length - 5} more transactions',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.45))),
              ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/transactions');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(context.t('view_all')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/add-transaction');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(context.t('add_transaction')),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showCalendarSheet(
    BuildContext context,
    MonthlyAnalytics analytics,
    String currency,
    List<TransactionModel> transactions,
    bool hideAmounts,
    bool isDark,
    Color primary,
  ) {
    _calendarMonth = DateTime(analytics.month.year, analytics.month.month, 1);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final viewMonth =
                DateTime(_calendarMonth.year, _calendarMonth.month, 1);
            final monthAnalytics = ref.read(monthlyAnalyticsProvider(viewMonth));
            final canGoNext =
                viewMonth.year < DateTime.now().year ||
                    (viewMonth.year == DateTime.now().year &&
                        viewMonth.month < DateTime.now().month);

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78,
              minChildSize: 0.55,
              maxChildSize: 0.92,
              builder: (_, controller) => Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
                  children: [
                    Center(
                        child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primary.withValues(alpha: 0.15),
                            primary.withValues(alpha: 0.06),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.calendar_month_rounded,
                              size: 20,
                              color: primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.t('daily_expense_heatmap'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('MMMM yyyy').format(viewMonth),
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setSheetState(() {
                                _calendarMonth = DateTime(
                                  _calendarMonth.year,
                                  _calendarMonth.month - 1,
                                  1,
                                );
                              });
                            },
                            icon: const Icon(Icons.chevron_left_rounded),
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            onPressed: canGoNext
                                ? () {
                                    setSheetState(() {
                                      _calendarMonth = DateTime(
                                        _calendarMonth.year,
                                        _calendarMonth.month + 1,
                                        1,
                                      );
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_right_rounded),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildCalendarSection(
                      monthAnalytics,
                      currency,
                      transactions,
                      hideAmounts,
                      isDark,
                      primary,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Line Trend ───────────────────────────────────────────────────────────

  Widget _buildLineTrend(MonthlyAnalytics analytics, String currency,
      bool hideAmounts, bool isDark, Color primary) {
    final month = analytics.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final expenseByDay = List<double>.filled(daysInMonth, 0);
    final incomeByDay = List<double>.filled(daysInMonth, 0);
    final netByDay = List<double>.filled(daysInMonth, 0);

    for (final t in analytics.transactions) {
      final i = t.date.day - 1;
      if (i < 0 || i >= daysInMonth) continue;
      if (t.type == TransactionType.expense) {
        expenseByDay[i] += t.amount;
        netByDay[i] -= t.amount;
      } else {
        incomeByDay[i] += t.amount;
        netByDay[i] += t.amount;
      }
    }

    final allVals = [
      ...expenseByDay,
      ...incomeByDay,
      ...netByDay.map((e) => e.abs()),
    ];
    final maxValue =
        allVals.isEmpty ? 1.0 : allVals.reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    final spotsExpense = <FlSpot>[];
    final spotsIncome = <FlSpot>[];
    final spotsNet = <FlSpot>[];
    for (var i = 0; i < daysInMonth; i++) {
      spotsExpense.add(FlSpot(i.toDouble() + 1, expenseByDay[i]));
      spotsIncome.add(FlSpot(i.toDouble() + 1, incomeByDay[i]));
      spotsNet.add(FlSpot(i.toDouble() + 1, netByDay[i].abs()));
    }

    return _card(
      context,
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
              context, context.t('daily_trend'), Icons.show_chart_rounded, primary),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _legendDot(context.t('income'), AppColors.success),
              _legendDot(context.t('expense'), AppColors.error),
              _legendDot(context.t('net_savings'), AppColors.info),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.t('income_vs_expense',
                params: {'month': DateFormat('MMM yyyy').format(month)}),
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: daysInMonth.toDouble(),
                minY: 0,
                maxY: safeMax * 1.25,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: safeMax / 5,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.25),
                    strokeWidth: 0.8,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            hideAmounts ? '••' : _fmtShort(value),
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.35)),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 7,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 7 != 0 &&
                            value.toInt() != daysInMonth) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(value.toInt().toString(),
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4))),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        isDark ? const Color(0xFF1E2A3A) : Colors.white,
                    tooltipBorderRadius: BorderRadius.circular(10),
                    tooltipBorder: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12),
                    getTooltipItems: (spots) => spots.map((spot) {
                      final color = spot.barIndex == 0
                          ? AppColors.error
                          : spot.barIndex == 1
                              ? AppColors.success
                              : AppColors.info;
                      final label = spot.barIndex == 0
                          ? context.t('expense_short')
                          : spot.barIndex == 1
                              ? context.t('income_short')
                              : context.t('net_savings');
                      return LineTooltipItem(
                          '$label: ${_fmtShort(spot.y)}',
                          TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12));
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  _lineData(
                    spotsExpense,
                    AppColors.error,
                    isAccent: true,
                  ),
                  _lineData(
                    spotsIncome,
                    AppColors.success,
                    isAccent: true,
                  ),
                  _lineData(
                    spotsNet,
                    AppColors.info,
                    isAccent: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _lineData(List<FlSpot> spots, Color color,
      {required bool isAccent}) {
    return LineChartBarData(
      spots: spots,
      color: color,
      barWidth: isAccent ? 2.8 : 2.2,
      isCurved: true,
      curveSmoothness: 0.35,
      dotData: FlDotData(
        show: isAccent,
        getDotPainter: (spot, _, __, ___) {
          if (spot.y == 0) {
            return FlDotCirclePainter(
                radius: 0,
                color: Colors.transparent,
                strokeWidth: 0,
                strokeColor: Colors.transparent);
          }
          return FlDotCirclePainter(
              radius: isAccent ? 3 : 2,
              color: color,
              strokeWidth: 1.5,
              strokeColor: Colors.white);
        },
        checkToShowDot: (spot, _) => isAccent && spot.y > 0,
      ),
      isStrokeCapRound: true,
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: isAccent ? 0.22 : 0.12),
            color.withValues(alpha: 0.0)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────────

  Widget _card(BuildContext context, bool isDark, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardHeader(
      BuildContext context, String title, IconData icon, Color primary) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: primary),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: -0.3,
              color: Theme.of(context).colorScheme.onSurface,
            )),
      ],
    );
  }

  Widget _emptyState(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 40,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.15)),
            const SizedBox(height: 10),
            Text(text,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.35))),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6))),
      ],
    );
  }

  String _fmtShort(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}
