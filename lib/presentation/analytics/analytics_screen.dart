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
import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  bool _revealAmounts = false;
  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  late AnimationController _animCtrl;

  // 0 = Expense, 1 = Income for Category Breakdown
  int _categoryTypeIndex = 0;
  // 0 = Donut, 1 = Bar Chart
  int _categoryChartStyle = 0;
  int _touchedCategoryIndex = -1;

  // 0 = Expense, 1 = Income for Line Trend
  int _trendViewIndex = 0;
  int _nearestTouchBar = 0;

  // Pre-created animations to avoid CurvedAnimation leak in build().
  static const List<int> _animDelays = [0, 80, 160, 240, 320, 400];
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
    final idx = index.clamp(0, _fadeAnims.length - 1);
    return FadeTransition(
      opacity: _fadeAnims[idx],
      child: SlideTransition(
        position: _slideAnims[idx],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analytics = ref.watch(monthlyAnalyticsProvider(_selectedMonth));
    final categories = ref.watch(categoriesProvider);
    final accounts = ref.watch(accountsProvider);
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
            // 0. Header with Month Navigator & Actions
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
                  primary,
                ),
              ),
            ),

            // 1. Core Financial KPI Summary Cards + MoM indicator
            SliverToBoxAdapter(
              child: _anim(
                index: 1,
                child: _buildSummaryCards(
                  analytics,
                  currency,
                  effectiveHide,
                  toggleReveal,
                  isDark,
                  primary,
                ),
              ),
            ),

            // 2. Category Breakdown (Donut + Bar with Expense/Income toggle)
            SliverToBoxAdapter(
              child: _anim(
                index: 2,
                child: _buildCategoryBreakdown(
                  analytics,
                  categories,
                  currency,
                  effectiveHide,
                  isDark,
                  primary,
                ),
              ),
            ),

            // 3. Accounts & Wallets Breakdown (bKash, Nagad, Bank, Cash)
            SliverToBoxAdapter(
              child: _anim(
                index: 3,
                child: _buildAccountBreakdown(
                  analytics,
                  accounts,
                  currency,
                  effectiveHide,
                  isDark,
                  primary,
                ),
              ),
            ),

            // 4. Daily Spending Pace & Allowance Card
            SliverToBoxAdapter(
              child: _anim(
                index: 4,
                child: _buildDailyAllowanceAnalyticsCard(
                  context,
                  settings,
                  transactions,
                  currency,
                  effectiveHide,
                  isDark,
                  primary,
                ),
              ),
            ),

            // 5. Daily Trend Curve (Expense / Income)
            SliverToBoxAdapter(
              child: _anim(
                index: 5,
                child: _buildLineTrend(
                  analytics,
                  currency,
                  effectiveHide,
                  isDark,
                  primary,
                ),
              ),
            ),

            // 6. Inline Calendar Expense Heatmap
            SliverToBoxAdapter(
              child: _anim(
                index: 5,
                child: _buildInlineCalendarSection(
                  context,
                  analytics,
                  currency,
                  transactions,
                  effectiveHide,
                  isDark,
                  primary,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  // ── Header & Month Navigator ─────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    MonthlyAnalytics analytics,
    String currency,
    List<TransactionModel> transactions,
    bool effectiveHide,
    bool isDark,
    bool hideAmounts,
    VoidCallback toggleReveal,
    Color primary,
  ) {
    final now = DateTime.now();
    final canGoNext = _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  context.t('analytics'),
                  style: AppTextStyles.headingLg.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (hideAmounts) ...[
                _iconBtn(
                  context,
                  _revealAmounts
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  isDark,
                  toggleReveal,
                  tooltip: 'Toggle amounts',
                ),
                const SizedBox(width: 8),
              ],
              _iconBtn(
                context,
                Icons.calendar_month_rounded,
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
                tooltip: context.t('daily_expense_heatmap'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Month Switcher Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 22),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month - 1,
                        1,
                      );
                      _touchedCategoryIndex = -1;
                    });
                  },
                  visualDensity: VisualDensity.compact,
                  splashRadius: 18,
                ),
                InkWell(
                  onTap: () => _pickMonthDialog(context, primary, isDark),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_note_rounded, size: 16, color: primary),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMMM yyyy').format(_selectedMonth),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 22),
                  onPressed: canGoNext
                      ? () {
                          setState(() {
                            _selectedMonth = DateTime(
                              _selectedMonth.year,
                              _selectedMonth.month + 1,
                              1,
                            );
                            _touchedCategoryIndex = -1;
                          });
                        }
                      : null,
                  visualDensity: VisualDensity.compact,
                  splashRadius: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _pickMonthDialog(BuildContext context, Color primary, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final now = DateTime.now();
        final currentSelected = _selectedMonth;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Month',
                style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: List.generate(12, (index) {
                  final monthDate = DateTime(now.year, now.month - index, 1);
                  final isCurrent = currentSelected.year == monthDate.year &&
                      currentSelected.month == monthDate.month;
                  return ChoiceChip(
                    label: Text(DateFormat('MMM yyyy').format(monthDate)),
                    selected: isCurrent,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedMonth = monthDate;
                          _touchedCategoryIndex = -1;
                        });
                        Navigator.pop(ctx);
                      }
                    },
                    selectedColor: primary.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: isCurrent
                          ? primary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12.5,
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _iconBtn(
    BuildContext context,
    IconData icon,
    bool isDark,
    VoidCallback onTap, {
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  // ── Summary Cards (KPIs + MoM Growth) ────────────────────────────────────

  Widget _buildSummaryCards(
    MonthlyAnalytics analytics,
    String currency,
    bool hideAmounts,
    VoidCallback toggleReveal,
    bool isDark,
    Color primary,
  ) {
    final savingsRate = analytics.savingsRate;
    final rateColor = savingsRate >= 20
        ? AppColors.success
        : savingsRate >= 10
            ? AppColors.warning
            : AppColors.error;
    final isPositiveSavings = analytics.netSavings >= 0;
    final momPct = analytics.expenseChangePercentage;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
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
                  gradientColors: const [Color(0xFF10B981), Color(0xFF34D399)],
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
                  gradientColors: const [Color(0xFFEF4444), Color(0xFFF87171)],
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
                      ? const [Color(0xFF3B82F6), Color(0xFF60A5FA)]
                      : const [Color(0xFFEF4444), Color(0xFFF87171)],
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
                      ? const [Color(0xFF10B981), Color(0xFF34D399)]
                      : rateColor == AppColors.warning
                          ? const [Color(0xFFF59E0B), Color(0xFFFBBF24)]
                          : const [Color(0xFFEF4444), Color(0xFFF87171)],
                ),
              ),
            ],
          ),

          // MoM Growth Indicator Badge
          if (momPct != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: (momPct <= 0 ? AppColors.success : AppColors.warning)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (momPct <= 0 ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    momPct < -0.5
                        ? Icons.trending_down_rounded
                        : momPct > 0.5
                            ? Icons.trending_up_rounded
                            : Icons.trending_flat_rounded,
                    size: 16,
                    color: momPct <= 0 ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      momPct < -0.5
                          ? context.t('mom_spending_decreased',
                              params: {'pct': momPct.abs().toStringAsFixed(1)})
                          : momPct > 0.5
                              ? context.t('mom_spending_increased',
                                  params: {'pct': momPct.toStringAsFixed(1)})
                              : context.t('mom_spending_same'),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color:
                            momPct <= 0 ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.4,
                  height: 1.1,
                ),
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
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category Breakdown (Donut + Bar with Expense/Income toggle) ──────────

  Widget _buildCategoryBreakdown(
    MonthlyAnalytics analytics,
    List<CategoryModel> categories,
    String currency,
    bool effectiveHide,
    bool isDark,
    Color primary,
  ) {
    final isExpense = _categoryTypeIndex == 0;
    final breakdown = analytics.getCategoryBreakdown(
      isExpense ? TransactionType.expense : TransactionType.income,
    );
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

    // Values converted from Paisa to Taka
    final entries = breakdown.entries
        .map((e) => MapEntry(e.key, e.value / 100.0))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalTaka = entries.fold<double>(0.0, (sum, e) => sum + e.value);
    final top = entries.take(6).toList();

    return _card(
      context,
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Chart Mode (Donut vs Bar) and Type Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _cardHeader(
                  context,
                  context.t('category_breakdown'),
                  Icons.pie_chart_outline_rounded,
                  primary,
                ),
              ),
              // Donut / Bar toggle buttons
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _chartTypeIconBtn(
                      icon: Icons.donut_large_rounded,
                      isSelected: _categoryChartStyle == 0,
                      onTap: () => setState(() => _categoryChartStyle = 0),
                      primary: primary,
                    ),
                    _chartTypeIconBtn(
                      icon: Icons.bar_chart_rounded,
                      isSelected: _categoryChartStyle == 1,
                      onTap: () => setState(() => _categoryChartStyle = 1),
                      primary: primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Expense vs Income Filter Chips
          Row(
            children: [
              _trendToggleChip(
                label: context.t('expense'),
                isSelected: isExpense,
                color: AppColors.error,
                isDark: isDark,
                onTap: () {
                  if (_categoryTypeIndex != 0) {
                    setState(() {
                      _categoryTypeIndex = 0;
                      _touchedCategoryIndex = -1;
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              _trendToggleChip(
                label: context.t('income'),
                isSelected: !isExpense,
                color: AppColors.success,
                isDark: isDark,
                onTap: () {
                  if (_categoryTypeIndex != 1) {
                    setState(() {
                      _categoryTypeIndex = 1;
                      _touchedCategoryIndex = -1;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (top.isEmpty)
            _emptyState(
              context,
              isExpense
                  ? context.t('no_expense_month')
                  : context.t('no_income_month'),
            )
          else ...[
            if (_categoryChartStyle == 0)
              // Donut Chart View
              _buildDonutChartView(
                top,
                totalTaka,
                categoryMap,
                currency,
                effectiveHide,
                isDark,
                primary,
                isBangla,
              )
            else
              // Fixed Bar Chart View
              _buildBarChartView(
                top,
                categoryMap,
                currency,
                effectiveHide,
                isDark,
              ),

            const SizedBox(height: 18),
            const Divider(height: 1, thickness: 0.6),
            const SizedBox(height: 14),

            // Top Categories Ranked List with Percentages
            ...List.generate(top.length, (i) {
              final catId = top[i].key;
              final amountTaka = top[i].value;
              final cat = categoryMap[catId];
              final catName =
                  (isBangla ? cat?.nameBn : cat?.name) ?? cat?.name ?? catId;
              final pct = totalTaka > 0 ? (amountTaka / totalTaka * 100) : 0.0;
              final color =
                  AppColors.chartColors[i % AppColors.chartColors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            catName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          formatAmount(currency, (amountTaka * 100).toInt(),
                              hide: effectiveHide),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _chartTypeIconBtn({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected
              ? primary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  Widget _buildDonutChartView(
    List<MapEntry<String, double>> top,
    double totalTaka,
    Map<String, CategoryModel> categoryMap,
    String currency,
    bool effectiveHide,
    bool isDark,
    Color primary,
    bool isBangla,
  ) {
    final hasTouch =
        _touchedCategoryIndex >= 0 && _touchedCategoryIndex < top.length;
    final selectedEntry = hasTouch ? top[_touchedCategoryIndex] : null;
    final selectedCat =
        selectedEntry != null ? categoryMap[selectedEntry.key] : null;
    final selectedName = selectedCat != null
        ? (isBangla ? selectedCat.nameBn : selectedCat.name)
        : (isBangla ? 'মোট' : 'Total');
    final selectedAmount = selectedEntry != null ? selectedEntry.value : totalTaka;
    final selectedPct =
        hasTouch && totalTaka > 0 ? (selectedEntry!.value / totalTaka * 100) : 100.0;
    final selectedColor = hasTouch
        ? AppColors.chartColors[
            _touchedCategoryIndex % AppColors.chartColors.length]
        : primary;

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response?.touchedSection == null) {
                      _touchedCategoryIndex = -1;
                      return;
                    }
                    _touchedCategoryIndex =
                        response!.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 58,
              sections: List.generate(top.length, (i) {
                final isTouched = i == _touchedCategoryIndex;
                final val = top[i].value;
                final color =
                    AppColors.chartColors[i % AppColors.chartColors.length];
                return PieChartSectionData(
                  color: isTouched ? color : color.withValues(alpha: 0.88),
                  value: val,
                  title: '',
                  showTitle: false,
                  radius: isTouched ? 34 : 26,
                  borderSide: isTouched
                      ? BorderSide(
                          color: Colors.white.withValues(alpha: 0.7), width: 2)
                      : BorderSide.none,
                );
              }),
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedName,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                formatAmount(currency, (selectedAmount * 100).toInt(),
                    hide: effectiveHide),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.4,
                ),
              ),
              if (hasTouch)
                Text(
                  '${selectedPct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selectedColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartView(
    List<MapEntry<String, double>> top,
    Map<String, CategoryModel> categoryMap,
    String currency,
    bool effectiveHide,
    bool isDark,
  ) {
    final highest = top.isEmpty
        ? 1.0
        : top.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final maxY = highest <= 0 ? 1.0 : highest * 1.25;

    return SizedBox(
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
              color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
              strokeWidth: 0.8,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= top.length) {
                    return const SizedBox.shrink();
                  }
                  final name = categoryMap[top[i].key]?.name ?? top[i].key;
                  final label =
                      name.length > 6 ? '${name.substring(0, 6)}.' : name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
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
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < top.length; i++)
              _makeGroupData(
                i,
                top[i].value, // Real Taka value (no extra division bug!)
                AppColors.chartColors[i % AppColors.chartColors.length],
                maxY,
              ),
          ],
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? const Color(0xFF1E2A3A) : Colors.white,
              tooltipBorderRadius: BorderRadius.circular(10),
              tooltipBorder:
                  BorderSide(color: isDark ? Colors.white12 : Colors.black12),
              getTooltipItem: (group, _, rod, __) {
                final i = group.x;
                if (i < 0 || i >= top.length) return null;
                final name = categoryMap[top[i].key]?.name ?? top[i].key;
                final color =
                    AppColors.chartColors[i % AppColors.chartColors.length];
                return BarTooltipItem(
                  effectiveHide
                      ? '$name\n••••'
                      : '$name\n$currency${rod.toY.toStringAsFixed(0)}',
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(
      int x, double yInTaka, Color color, double maxY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: yInTaka, // Corrected scale: exact value in Taka!
          width: 24,
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

  // ── Accounts & Wallets Breakdown (bKash, Nagad, Bank, Cash) ─────────────

  Widget _buildAccountBreakdown(
    MonthlyAnalytics analytics,
    List<AccountModel> accounts,
    String currency,
    bool effectiveHide,
    bool isDark,
    Color primary,
  ) {
    final accountExpenseMap =
        analytics.getAccountBreakdown(TransactionType.expense);
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';

    final accountMap = {for (final a in accounts) a.id: a};

    final entries = accountExpenseMap.entries
        .map((e) => MapEntry(e.key, e.value / 100.0))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalAccountExpense =
        entries.fold<double>(0.0, (sum, e) => sum + e.value);

    return _card(
      context,
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            context,
            context.t('accounts_breakdown'),
            Icons.account_balance_wallet_rounded,
            primary,
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            _emptyState(context, context.t('no_account_data'))
          else
            ...entries.map((entry) {
              final acc = accountMap[entry.key];
              final name = acc != null
                  ? (acc.nickname?.isNotEmpty == true
                      ? acc.nickname!
                      : (isBangla ? acc.nameBn : acc.name))
                  : 'Other / Cash';
              final pct = totalAccountExpense > 0
                  ? (entry.value / totalAccountExpense * 100)
                  : 0.0;
              final accColor = _getAccountColor(acc?.type);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_getAccountIcon(acc?.type),
                                size: 16, color: accColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${pct.toStringAsFixed(1)}% of expenses',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatAmount(currency, (entry.value * 100).toInt(),
                                hide: effectiveHide),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (pct / 100).clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: accColor.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(accColor),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _getAccountColor(AccountType? type) {
    switch (type) {
      case AccountType.mfs:
        return const Color(0xFFE2136E); // bKash/MFS pinkish red
      case AccountType.bank:
        return const Color(0xFF2563EB); // Bank blue
      case AccountType.cash:
        return const Color(0xFF10B981); // Cash green
      case AccountType.creditCard:
        return const Color(0xFFF59E0B); // Amber
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _getAccountIcon(AccountType? type) {
    switch (type) {
      case AccountType.mfs:
        return Icons.phone_android_rounded;
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.creditCard:
        return Icons.credit_card_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  // ── Daily Allowance Analytics Card ───────────────────────────────────────

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
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        padding: const EdgeInsets.all(16),
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
              offset: const Offset(0, 3),
            ),
          ],
        ),
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
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('daily_pace_card_title'),
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.t('daily_pace_desc'),
                    style: AppTextStyles.caption.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () =>
                  _showDailyBudgetDialog(context, settings, currency),
              style: TextButton.styleFrom(
                backgroundColor: primary.withValues(alpha: 0.12),
                foregroundColor: primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                context.t('setup'),
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
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
        return txDay
            .isAfter(startDateNormalized.subtract(const Duration(days: 1)));
      }).fold<int>(0, (sum, t) => sum + t.amount);
    } else {
      totalSpent = todaysSpent;
    }

    final remaining = expectedLimit - totalSpent;
    final percentage = expectedLimit > 0
        ? (totalSpent / expectedLimit).clamp(0.0, 1.0)
        : 0.0;
    final isOverBudget = remaining < 0;

    final monthStart = DateTime(now.year, now.month, 1);
    final daysInMonthSoFar = now.day;
    final monthExpense = transactions.where((t) {
      if (t.type != TransactionType.expense || t.isDeleted) return false;
      final s = DateTime(monthStart.year, monthStart.month, 1);
      final e = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      return !t.date.isBefore(s) && !t.date.isAfter(e);
    }).fold<int>(0, (sum, t) => sum + t.amount);
    final avgDailyExpense =
        daysInMonthSoFar > 0 ? (monthExpense / daysInMonthSoFar).round() : 0;

    String paceStatus;
    Color paceColor;
    IconData paceIcon;

    if (isOverBudget) {
      paceStatus = context.t('exceeded_pace');
      paceColor = AppColors.error;
      paceIcon = Icons.warning_amber_rounded;
    } else if (todaysSpent > dailyLimit) {
      paceStatus = context.t('above_target');
      paceColor = AppColors.warning;
      paceIcon = Icons.trending_up_rounded;
    } else if (dailyRollover && daysPassed > 1 && remaining > 0) {
      paceStatus = context.t('savings_rollover');
      paceColor = const Color(0xFF10B981);
      paceIcon = Icons.savings_rounded;
    } else {
      paceStatus = context.t('on_track');
      paceColor = const Color(0xFF10B981);
      paceIcon = Icons.check_circle_outline_rounded;
    }

    String formatAmt(num val) =>
        formatAmount(currency, val, decimals: 0, hide: effectiveHide);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(18),
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
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(11),
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
                            context.t('daily_pace_card_title'),
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            dailyRollover
                                ? '$daysPassed Days Rollover'
                                : 'Daily Budget Tracking',
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () =>
                        _showDailyBudgetDialog(context, settings, currency),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
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
                            context.t('edit'),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: context.t('today_spent'),
                  value: formatAmt(todaysSpent),
                  subText: '/ ${formatAmt(dailyLimit)} limit',
                  isDark: isDark,
                  primaryColor: const Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: context.t('available_left'),
                  value: formatAmt(remaining.abs()),
                  subText: isOverBudget
                      ? context.t('over_target')
                      : context.t('available'),
                  isDark: isDark,
                  primaryColor:
                      isOverBudget ? AppColors.error : AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: context.t('month_avg_day'),
                  value: formatAmt(avgDailyExpense),
                  subText: context.t('days_tracked',
                      params: {'count': '$daysInMonthSoFar'}),
                  isDark: isDark,
                  primaryColor: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.t('allowance_usage'),
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
              const SizedBox(height: 7),
              Stack(
                children: [
                  Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: paceColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: percentage,
                    child: Container(
                      height: 7,
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

  // ── Expense / Income Area Trend ──────────────────────────────────────────

  Widget _buildLineTrend(MonthlyAnalytics analytics, String currency,
      bool hideAmounts, bool isDark, Color primary) {
    final month = analytics.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final isExpenseView = _trendViewIndex == 0;
    final viewType =
        isExpenseView ? TransactionType.expense : TransactionType.income;

    int maxTxDay = isCurrentMonth ? now.day : daysInMonth;
    for (final t in analytics.transactions) {
      if (t.type == viewType && !t.isDeleted) {
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

    final catTotals = <String, double>{};
    final catDayMap = <String, List<double>>{};
    for (final t in analytics.transactions) {
      if (t.type != viewType || t.isDeleted) continue;
      final dayIdx = t.date.day - 1;
      if (dayIdx < 0 || dayIdx >= visibleDays) continue;
      catTotals[t.categoryId] = (catTotals[t.categoryId] ?? 0) + (t.amount / 100.0);
      catDayMap.putIfAbsent(
          t.categoryId, () => List<double>.filled(visibleDays, 0));
      catDayMap[t.categoryId]![dayIdx] += (t.amount / 100.0);
    }

    final sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCats = sortedCats.take(5).toList();

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

    double maxVal = 0;
    for (final entry in catCumulative.entries) {
      for (final v in entry.value) {
        if (v > maxVal) maxVal = v;
      }
    }
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    final catSpots = <String, List<FlSpot>>{};
    for (final cat in topCats) {
      final cumData = catCumulative[cat.key]!;
      catSpots[cat.key] = [
        for (var i = 0; i < visibleDays; i++)
          FlSpot(i.toDouble() + 1, cumData[i]),
      ];
    }

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

    const areaOpacities = [0.32, 0.26, 0.22, 0.18, 0.14];
    const lineWidths = [3.2, 2.8, 2.5, 2.2, 2.0];

    return _card(
      context,
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _cardHeader(
                  context,
                  context.t('daily_trend'),
                  Icons.area_chart_rounded,
                  primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          Text(
            '${isExpenseView ? context.t('expense') : context.t('income')} — ${DateFormat('MMM yyyy').format(month)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 14),
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
          if (topCats.isEmpty)
            _emptyState(
              context,
              isExpenseView
                  ? context.t('no_expense_month')
                  : context.t('no_income_month'),
            )
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
                                    .withValues(alpha: 0.35),
                              ),
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
                            child: Text(
                              v.toString(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4),
                              ),
                            ),
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
                      final spots = response.lineBarSpots!;
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
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                      getTooltipItems: (spots) {
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
                              height: 1.4,
                            ),
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

  // ── Inline Calendar Expense Heatmap ──────────────────────────────────────

  Widget _buildInlineCalendarSection(
    BuildContext context,
    MonthlyAnalytics analytics,
    String currency,
    List<TransactionModel> transactions,
    bool hideAmounts,
    bool isDark,
    Color primary,
  ) {
    return _card(
      context,
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _cardHeader(
                context,
                context.t('daily_expense_heatmap'),
                Icons.calendar_view_month_rounded,
                primary,
              ),
              InkWell(
                onTap: () => _showCalendarSheet(
                  context,
                  analytics,
                  currency,
                  transactions,
                  hideAmounts,
                  isDark,
                  primary,
                ),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        context.t('view_all'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded,
                          size: 16, color: primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildCalendarSection(
            analytics,
            currency,
            transactions,
            hideAmounts,
            isDark,
            primary,
          ),
        ],
      ),
    );
  }

  // ── Calendar Heatmap Widget ──────────────────────────────────────────────

  Widget _buildCalendarSection(
    MonthlyAnalytics analytics,
    String currency,
    List<TransactionModel> transactions,
    bool hideAmounts,
    bool isDark,
    Color primary,
  ) {
    final month = analytics.month;
    final startOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startOffset = startOfMonth.weekday - 1;

    final expenseByDay = <int, double>{};
    for (final t in analytics.transactions) {
      if (t.type == TransactionType.expense && !t.isDeleted) {
        expenseByDay[t.date.day] = (expenseByDay[t.date.day] ?? 0) + (t.amount / 100.0);
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
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.35),
                        ),
                      ),
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
                    !t.isDeleted &&
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
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 10,
                      color: amount > maxExpense * 0.3
                          ? Colors.white
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: isToday ? 1.0 : 0.6),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              context.t('less'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(
              5,
              (i) => Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1 + (i * 0.18)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              context.t('more'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDaySheet(
    BuildContext context,
    DateTime date,
    List<TransactionModel> dayTx,
    String currency,
    bool hideAmounts,
  ) {
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.calendar_today_rounded,
                      color: primary, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (dayTx.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 40,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.t('no_transactions'),
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
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
                  child: Row(
                    children: [
                      Icon(
                        isIncome
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: color,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.categoryId,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        hideAmounts
                            ? '••••'
                            : '${isIncome ? '+' : '-'}${formatAmount(currency, t.amount)}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            if (dayTx.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  context.t('more_transactions',
                      params: {'count': '${dayTx.length - 5}'}),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/transactions');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(context.t('add_transaction')),
                  ),
                ),
              ],
            ),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final viewMonth = _selectedMonth;
            final monthAnalytics =
                ref.watch(monthlyAnalyticsProvider(viewMonth));
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
                      ),
                    ),
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
                              setState(() {
                                _selectedMonth = DateTime(
                                  _selectedMonth.year,
                                  _selectedMonth.month - 1,
                                  1,
                                );
                              });
                              setSheetState(() {});
                            },
                            icon: const Icon(Icons.chevron_left_rounded),
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            onPressed: canGoNext
                                ? () {
                                    setState(() {
                                      _selectedMonth = DateTime(
                                        _selectedMonth.year,
                                        _selectedMonth.month + 1,
                                        1,
                                      );
                                    });
                                    setSheetState(() {});
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

  // ── Shared Helpers ───────────────────────────────────────────────────────

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
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: -0.3,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 40,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.15),
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.35),
              ),
            ),
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
                    BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            fontSize: 11,
            color: isBold
                ? color
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
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
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 9.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
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
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.15),
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
                            context.t('daily_pace_card_title'),
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
                    context.t('daily_pace_desc'),
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: context.t('daily_limit'),
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
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.15),
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
                            final parsed =
                                double.tryParse(controller.text.trim()) ?? 0.0;
                            final amount = (parsed * 100).toInt();
                            await ref
                                .read(settingsProvider.notifier)
                                .update('dailyBudgetLimit', amount);
                            if (rolloverValue != dailyRollover) {
                              if (rolloverValue &&
                                  settings['dailyBudgetStartDate'] == null) {
                                await ref
                                    .read(settingsProvider.notifier)
                                    .update(
                                      'dailyBudgetStartDate',
                                      DateTime.now().millisecondsSinceEpoch,
                                    );
                              }
                              await ref
                                  .read(settingsProvider.notifier)
                                  .update(
                                      'dailyBudgetRollover', rolloverValue);
                            } else if (amount > 0 &&
                                settings['dailyBudgetStartDate'] == null) {
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
                          child: const Text('Save Limit',
                              style: TextStyle(fontWeight: FontWeight.bold)),
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
