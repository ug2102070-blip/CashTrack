// lib/presentation/analytics/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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
  DateTime _calendarMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  late AnimationController _animCtrl;

  // Pre-created animations to avoid CurvedAnimation leak in build().
  static const List<int> _animDelays = [0, 80, 160, 320];
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnims = _animDelays.map((ms) {
      final s = (ms / 800).clamp(0.0, 1.0);
      final e = ((ms + 320) / 800).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _animCtrl, curve: Interval(s, e, curve: Curves.easeOut));
    }).toList();
    _slideAnims = _animDelays.map((ms) {
      final s = (ms / 800).clamp(0.0, 1.0);
      final e = ((ms + 320) / 800).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
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
                  index: 0,
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
                  index: 1,
                  child: _buildDailyAllowanceAnalyticsCard(
                      context,
                      settings,
                      transactions,
                      currency,
                      effectiveHide,
                      isDark,
                      primary)),
            ),
            SliverToBoxAdapter(
              child: _anim(
                  index: 2,
                  child: _buildCategoryBreakdown(
                      analytics, categories, isDark, primary)),
            ),
            SliverToBoxAdapter(
              child: _anim(
                  index: 3,
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
                  style: AppTextStyles.headingLg.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
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
            Icons.account_balance_wallet_outlined,
            isDark,
            () => _showMonthlySummarySheet(
              context,
              analytics,
              currency,
              effectiveHide,
              isDark,
              primary,
            ),
          ),
          const SizedBox(width: 8),
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
              ? AppColors.darkSurfaceElevated.withValues(alpha: 0.5)
              : AppColors.lightSurfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.4)
                : AppColors.lightBorder.withValues(alpha: 0.6),
          ),
        ),
        child: Icon(icon,
            size: 20,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            const SizedBox(height: 10),
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
            const SizedBox(height: 2),
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
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    final categoryMap = {
      '': CategoryModel(
        id: '',
        name: isBangla ? 'শ্রেণীহীন' : 'Uncategorized',
        nameBn: isBangla ? 'শ্রেণীহীন' : 'Uncategorized',
        icon: '🏷️',
        colorHex: '#9E9E9E',
        type: CategoryType.both,
      ),
      for (final c in categories) c.id: c
    };
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

  BarChartGroupData _makeGroupData(int x, num y, Color color, double maxY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: (y / 100).toDouble(),
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
                        fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
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
                        color:
                            AppColors.error.withValues(alpha: 0.1 + (i * 0.18)),
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
            final monthAnalytics =
                ref.read(monthlyAnalyticsProvider(viewMonth));
            final canGoNext = viewMonth.year < DateTime.now().year ||
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
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
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

  // ── Expense / Income Area Trend ──────────────────────────────────────────

  // 0 = Expense, 1 = Income
  int _trendViewIndex = 0;
  int _nearestTouchBar = 0; // tracked via touchCallback, no setState needed

  Widget _buildLineTrend(MonthlyAnalytics analytics, String currency,
      bool hideAmounts, bool isDark, Color primary) {
    final month = analytics.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final isExpenseView = _trendViewIndex == 0;
    final viewType =
        isExpenseView ? TransactionType.expense : TransactionType.income;

    // Find the max day among transactions of this type to support manually added future transactions
    int maxTxDay = now.day;
    for (final t in analytics.transactions) {
      if (t.type == viewType) {
        if (t.date.day > maxTxDay) {
          maxTxDay = t.date.day;
        }
      }
    }

    final visibleDays = isCurrentMonth
        ? math.min(daysInMonth, maxTxDay)
        : daysInMonth;

    final palette = isExpenseView
        ? AppColors.chartPaletteExpense
        : AppColors.chartPaletteIncome;

    // ── Gather per-category per-day data (only up to visibleDays) ──
    final catTotals = <String, double>{};
    final catDayMap = <String, List<double>>{};
    for (final t in analytics.transactions) {
      if (t.type != viewType) continue;
      final dayIdx = t.date.day - 1;
      if (dayIdx < 0 || dayIdx >= visibleDays) continue;
      catTotals[t.categoryId] = (catTotals[t.categoryId] ?? 0) + t.amount;
      catDayMap.putIfAbsent(
          t.categoryId, () => List<double>.filled(visibleDays, 0));
      catDayMap[t.categoryId]![dayIdx] += t.amount;
    }

    // Sort by total descending → top 5
    final sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCats = sortedCats.take(5).toList();

    // ── Build CUMULATIVE running totals for smooth flowing curves ──
    final catCumulative = <String, List<double>>{};
    for (final cat in topCats) {
      final dayData = catDayMap[cat.key]!;
      final cumList = List<double>.filled(visibleDays, 0);
      double running = 0;
      for (var i = 0; i < visibleDays; i++) {
        running += dayData[i];
        cumList[i] = running;
      }
      catCumulative[cat.key] = cumList;
    }

    // Max cumulative value
    double maxVal = 0;
    for (final entry in catCumulative.entries) {
      for (final v in entry.value) {
        if (v > maxVal) maxVal = v;
      }
    }
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    // Build spots from cumulative data (only up to visibleDays)
    final catSpots = <String, List<FlSpot>>{};
    for (final cat in topCats) {
      final cumData = catCumulative[cat.key]!;
      catSpots[cat.key] = [
        for (var i = 0; i < visibleDays; i++)
          FlSpot(i.toDouble() + 1, cumData[i]),
      ];
    }

    // Read categories for names
    final categories = ref.watch(categoriesProvider);
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    final categoryMap = {
      '': CategoryModel(
        id: '',
        name: isBangla ? 'শ্রেণীহীন' : 'Uncategorized',
        nameBn: isBangla ? 'শ্রেণীহীন' : 'Uncategorized',
        icon: '🏷️',
        colorHex: '#9E9E9E',
        type: CategoryType.both,
      ),
      for (final c in categories) c.id: c
    };

    // Area fill opacities – progressively lighter for lower-ranked categories
    const areaOpacities = [0.32, 0.26, 0.22, 0.18, 0.14];
    const lineWidths = [3.2, 2.8, 2.5, 2.2, 2.0];

    return _card(
      context,
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: _cardHeader(context, context.t('daily_trend'),
                    Icons.area_chart_rounded, primary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Toggle chips
          Row(
            children: [
              _trendToggleChip(
                label: context.t('expense'),
                isSelected: isExpenseView,
                color: AppColors.error,
                isDark: isDark,
                onTap: () => setState(() => _trendViewIndex = 0),
              ),
              const SizedBox(width: 8),
              _trendToggleChip(
                label: context.t('income'),
                isSelected: !isExpenseView,
                color: AppColors.success,
                isDark: isDark,
                onTap: () => setState(() => _trendViewIndex = 1),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Subtitle
          Text(
            '${isExpenseView ? context.t('expense') : context.t('income')} — ${DateFormat('MMM yyyy').format(month)}',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.38)),
          ),
          const SizedBox(height: 14),

          // Legend
          if (topCats.isNotEmpty) ...[
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                for (var i = 0; i < topCats.length; i++)
                  _legendDot(
                    categoryMap[topCats[i].key]?.name ?? topCats[i].key,
                    palette[i % palette.length],
                    isBold: i == 0,
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Chart
          if (topCats.isEmpty)
            _emptyState(
                context,
                isExpenseView
                    ? context.t('no_expense_month')
                    : 'No income data for this month')
          else
            SizedBox(
              height: 230,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: daysInMonth.toDouble(),
                  minY: 0,
                  maxY: safeMax * 1.15,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: safeMax / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.12),
                      strokeWidth: 0.6,
                      dashArray: [6, 6],
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
                        reservedSize: 42,
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
                                      .withValues(alpha: 0.30)),
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
                          final v = value.toInt();
                          if (v % 7 != 0 && v != daysInMonth) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(v.toString(),
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.35))),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchCallback:
                        (FlTouchEvent event, LineTouchResponse? response) {
                      if (response?.lineBarSpots == null ||
                          response!.lineBarSpots!.isEmpty) {
                        return;
                      }
                      // Approximate touch Y in data coordinates to find nearest line
                      final spots = response.lineBarSpots!;
                      // Try to get the touch pixel position from the event
                      double? touchPixelY;
                      if (event is FlTapDownEvent) {
                        touchPixelY = event.details.localPosition.dy;
                      }
                      if (event is FlPanUpdateEvent) {
                        touchPixelY = event.details.localPosition.dy;
                      }
                      if (event is FlLongPressStart) {
                        touchPixelY = event.details.localPosition.dy;
                      }
                      if (event is FlPanStartEvent) {
                        touchPixelY = event.details.localPosition.dy;
                      }
                      if (touchPixelY != null) {
                        // Convert pixel Y → approximate data Y (chart ~190px effective height)
                        final approxDataY = safeMax *
                            1.15 *
                            math.max(0, 1.0 - touchPixelY / 190.0);
                        int nearest = 0;
                        double minDist = double.infinity;
                        for (var i = 0; i < spots.length; i++) {
                          final d = (spots[i].y - approxDataY).abs();
                          if (d < minDist) {
                            minDist = d;
                            nearest = spots[i].barIndex;
                          }
                        }
                        _nearestTouchBar = nearest;
                      }
                    },
                    touchTooltipData: LineTouchTooltipData(
                      maxContentWidth: 160,
                      getTooltipColor: (_) =>
                          isDark ? const Color(0xFF1A2332) : Colors.white,
                      tooltipBorderRadius: BorderRadius.circular(14),
                      tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      tooltipBorder: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.06)),
                      getTooltipItems: (spots) {
                        // Show only the nearest touched line's tooltip
                        return spots.map((spot) {
                          if (spot.barIndex != _nearestTouchBar) return null;
                          final catIdx = spot.barIndex;
                          Color c;
                          String label;
                          if (catIdx < topCats.length) {
                            c = palette[catIdx % palette.length];
                            label = categoryMap[topCats[catIdx].key]?.name ??
                                topCats[catIdx].key;
                          } else {
                            c = Colors.grey;
                            label = '?';
                          }
                          return LineTooltipItem(
                            '$label: ${hideAmounts ? '••••' : '$currency${_fmtShort(spot.y)}'}',
                            TextStyle(
                                color: c,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                height: 1.4),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    for (var i = 0; i < topCats.length; i++)
                      _areaLineData(
                        catSpots[topCats[i].key]!,
                        palette[i % palette.length],
                        barWidth: lineWidths[i.clamp(0, lineWidths.length - 1)],
                        areaOpacity:
                            areaOpacities[i.clamp(0, areaOpacities.length - 1)],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _trendToggleChip({
    required String label,
    required bool isSelected,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.4)
                : isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? color
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
  }

  LineChartBarData _areaLineData(
    List<FlSpot> spots,
    Color color, {
    required double barWidth,
    required double areaOpacity,
  }) {
    return LineChartBarData(
      spots: spots,
      color: color,
      barWidth: barWidth,
      isCurved: true,
      curveSmoothness: 0.45,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      shadow: Shadow(
        color: color.withValues(alpha: 0.18),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: areaOpacity),
            color.withValues(alpha: areaOpacity * 0.5),
            color.withValues(alpha: 0.02),
          ],
          stops: const [0.0, 0.55, 1.0],
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

  Widget _legendDot(String label, Color color, {bool isBold = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: isBold ? 10 : 8,
            height: isBold ? 10 : 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: isBold
                  ? [
                      BoxShadow(
                          color: color.withValues(alpha: 0.4), blurRadius: 4)
                    ]
                  : null,
            )),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                fontSize: 11,
                color: isBold
                    ? color
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6))),
      ],
    );
  }

  Widget _buildDailyAllowanceAnalyticsCard(
    BuildContext context,
    Map<String, dynamic> settings,
    List<TransactionModel> transactions,
    String currency,
    bool effectiveHide,
    bool isDark,
    Color primary,
  ) {
    final dailyLimit = (settings['dailyBudgetLimit'] as num?)?.toInt() ?? 0;
    final dailyRollover = settings['dailyBudgetRollover'] as bool? ?? false;
    final startDateMs = settings['dailyBudgetStartDate'] as int?;

    if (dailyLimit <= 0) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.analytics_outlined,
                color: Color(0xFFF59E0B),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Allowance Analytics',
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Set a daily limit to track daily pace & unlimited rollover savings.',
                    style: AppTextStyles.caption.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _showDailyBudgetDialog(context, settings, currency),
              style: TextButton.styleFrom(
                backgroundColor: primary.withValues(alpha: 0.12),
                foregroundColor: primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Setup',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todaysSpent = transactions.where((t) {
      if (t.type != TransactionType.expense || t.isDeleted) return false;
      final txDay = DateTime(t.date.year, t.date.month, t.date.day);
      return txDay.isAtSameMomentAs(today);
    }).fold<int>(0, (sum, t) => sum + t.amount);

    int daysPassed = 1;
    int expectedLimit = dailyLimit;
    int totalSpent = 0;

    if (dailyRollover && startDateMs != null) {
      final start = DateTime.fromMillisecondsSinceEpoch(startDateMs);
      final startDateNormalized = DateTime(start.year, start.month, start.day);
      daysPassed = today.difference(startDateNormalized).inDays + 1;
      if (daysPassed < 1) daysPassed = 1;
      expectedLimit = dailyLimit * daysPassed;

      totalSpent = transactions.where((t) {
        if (t.type != TransactionType.expense || t.isDeleted) return false;
        final txDay = DateTime(t.date.year, t.date.month, t.date.day);
        return txDay.isAfter(startDateNormalized.subtract(const Duration(days: 1)));
      }).fold<int>(0, (sum, t) => sum + t.amount);
    } else {
      totalSpent = todaysSpent;
    }

    final remaining = expectedLimit - totalSpent;
    final percentage = expectedLimit > 0 ? (totalSpent / expectedLimit).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = remaining < 0;

    final monthStart = DateTime(now.year, now.month, 1);
    final daysInMonthSoFar = now.day;
    final monthExpense = transactions.where((t) {
      if (t.type != TransactionType.expense || t.isDeleted) return false;
      return t.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
          t.date.isBefore(now.add(const Duration(days: 1)));
    }).fold<int>(0, (sum, t) => sum + t.amount);
    final avgDailyExpense = daysInMonthSoFar > 0 ? (monthExpense / daysInMonthSoFar).round() : 0;

    String paceStatus;
    Color paceColor;
    IconData paceIcon;

    if (isOverBudget) {
      paceStatus = 'Exceeded Pace';
      paceColor = AppColors.error;
      paceIcon = Icons.warning_amber_rounded;
    } else if (todaysSpent > dailyLimit) {
      paceStatus = 'Above Target';
      paceColor = AppColors.warning;
      paceIcon = Icons.trending_up_rounded;
    } else if (dailyRollover && daysPassed > 1 && remaining > 0) {
      paceStatus = 'Savings Rollover';
      paceColor = const Color(0xFF10B981);
      paceIcon = Icons.savings_rounded;
    } else {
      paceStatus = 'On Track';
      paceColor = const Color(0xFF10B981);
      paceIcon = Icons.check_circle_outline_rounded;
    }

    String formatAmt(num val) =>
        formatAmount(currency, val, decimals: 0, hide: effectiveHide);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.speed_rounded,
                        color: Color(0xFFF59E0B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Pace & Allowance',
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            dailyRollover
                                ? '$daysPassed ${daysPassed == 1 ? 'Day' : 'Days'} Unlimited Carry Forward'
                                : 'Daily Budget Tracker',
                            style: AppTextStyles.caption.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: paceColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: paceColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(paceIcon, size: 13, color: paceColor),
                        const SizedBox(width: 4),
                        Text(
                          paceStatus,
                          style: AppTextStyles.caption.copyWith(
                            color: paceColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showDailyBudgetDialog(context, settings, currency),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, size: 13, color: primary),
                          const SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: AppTextStyles.caption.copyWith(
                              color: primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'Today Spent',
                  value: formatAmt(todaysSpent),
                  subText: '/ ${formatAmt(dailyLimit)} limit',
                  isDark: isDark,
                  primaryColor: const Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'Available Left',
                  value: formatAmt(remaining.abs()),
                  subText: isOverBudget ? 'over target' : 'available',
                  isDark: isDark,
                  primaryColor: isOverBudget ? AppColors.error : AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'Month Avg/Day',
                  value: formatAmt(avgDailyExpense),
                  subText: '$daysInMonthSoFar days tracked',
                  isDark: isDark,
                  primaryColor: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Allowance Usage',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: paceColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: paceColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: percentage,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            paceColor.withValues(alpha: 0.7),
                            paceColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required String subText,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.55),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: primaryColor,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subText,
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
              fontSize: 9.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showMonthlySummarySheet(
    BuildContext context,
    MonthlyAnalytics analytics,
    String currency,
    bool hideAmounts,
    bool isDark,
    Color primary,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? AppColors.darkSurface
          : Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 70),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Overview',
                      style: AppTextStyles.h5.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummaryCards(
                    analytics, currency, hideAmounts, () {}, isDark, primary),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmtShort(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  Future<void> _showDailyBudgetDialog(
    BuildContext context,
    Map<String, dynamic> settings,
    String currency,
  ) async {
    final dailyLimit = (settings['dailyBudgetLimit'] as num?)?.toInt() ?? 0;
    final dailyRollover = settings['dailyBudgetRollover'] as bool? ?? false;
    final controller = TextEditingController(
      text: dailyLimit > 0 ? (dailyLimit / 100).toStringAsFixed(0) : '',
    );
    bool rolloverValue = dailyRollover;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primary = Theme.of(context).colorScheme.primary;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface
                    : Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.speed_rounded,
                              color: Color(0xFFF59E0B),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Daily Budget Pace & Limit',
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Set your target daily expense limit to automatically track daily spending pace.',
                    style: AppTextStyles.caption.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Daily Limit',
                      prefixText: '$currency ',
                      hintText: 'e.g. 500',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    autofocus: dailyLimit <= 0,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.savings_rounded,
                            color: Color(0xFF10B981),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unlimited Carry Forward',
                                style: AppTextStyles.body2.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Rollover unspent daily budget to next days',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: rolloverValue,
                          onChanged: (v) {
                            setSheetState(() => rolloverValue = v);
                          },
                          activeTrackColor: primary.withValues(alpha: 0.45),
                          activeThumbColor: primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            context.go('/budget');
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('All Budgets'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final parsed = double.tryParse(controller.text.trim()) ?? 0.0;
                            final amount = (parsed * 100).toInt();
                            await ref.read(settingsProvider.notifier).update('dailyBudgetLimit', amount);
                            if (rolloverValue != dailyRollover) {
                              if (rolloverValue && settings['dailyBudgetStartDate'] == null) {
                                await ref.read(settingsProvider.notifier).update(
                                  'dailyBudgetStartDate',
                                  DateTime.now().millisecondsSinceEpoch,
                                );
                              }
                              await ref.read(settingsProvider.notifier).update('dailyBudgetRollover', rolloverValue);
                            } else if (amount > 0 && settings['dailyBudgetStartDate'] == null) {
                              await ref.read(settingsProvider.notifier).update(
                                'dailyBudgetStartDate',
                                DateTime.now().millisecondsSinceEpoch,
                              );
                            }
                            if (!sheetContext.mounted) return;
                            Navigator.pop(sheetContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Save Limit', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
