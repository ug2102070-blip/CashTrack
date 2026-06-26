// lib/presentation/dashboard/widgets/expense_chart_dynamic.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../../data/models/transaction_model.dart';

class ExpenseChartDynamic extends ConsumerStatefulWidget {
  final bool compact;
  final bool showLegend;

  const ExpenseChartDynamic({
    super.key,
    this.compact = false,
    this.showLegend = true,
  });

  @override
  ConsumerState<ExpenseChartDynamic> createState() =>
      _ExpenseChartDynamicState();
}

class _ExpenseChartDynamicState extends ConsumerState<ExpenseChartDynamic>
    with SingleTickerProviderStateMixin {
  int touchedIndex = -1;
  bool showExpense = true;

  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider);
    final catMap = {for (final c in categories) c.id: c.name};
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final categoryData = _calculateCategoryData(
      transactions,
      showExpense ? TransactionType.expense : TransactionType.income,
    );
    final entries = categoryData.entries.toList();
    final safeTouchedIndex =
        (touchedIndex >= 0 && touchedIndex < entries.length)
            ? touchedIndex
            : -1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: EdgeInsets.all(widget.compact ? 16 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          if (!isDark)
            BoxShadow(
              color: primary.withValues(alpha: 0.04),
              blurRadius: 40,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  showExpense
                      ? context.t('expense_breakdown')
                      : context.t('income_breakdown'),
                  style: AppTextStyles.h5.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Compact toggle
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildToggleBtn(context.t('expense'), true, primary),
                    _buildToggleBtn(context.t('income'), false, primary),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (categoryData.isEmpty)
            _buildEmptyChart()
          else
            _buildChart(categoryData, catMap, safeTouchedIndex),

          if (widget.showLegend && categoryData.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildLegendSection(categoryData, catMap, safeTouchedIndex),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String text, bool forExpense, Color primary) {
    final isSelected = showExpense == forExpense;
    return GestureDetector(
      onTap: () {
        if (showExpense != forExpense) {
          setState(() {
            showExpense = forExpense;
            touchedIndex = -1;
            _categoryIndexMap.clear();
          });
          _animController.reset();
          _animController.forward();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Map<String, double> _calculateCategoryData(
    List<TransactionModel> transactions,
    TransactionType type,
  ) {
    final Map<String, double> data = {};
    for (var t in transactions.where((t) => t.type == type)) {
      data[t.categoryId] = (data[t.categoryId] ?? 0) + t.amount;
    }
    // Sort by value descending
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  double _getTotal(Map<String, double> data) =>
      data.values.fold(0, (s, a) => s + a);

  List<PieChartSectionData> _getSections(
    Map<String, double> data,
    double baseRadius,
    double touchedRadius,
    int safeTouchedIndex,
  ) {
    final entries = data.entries.toList();
    return List.generate(entries.length, (i) {
      final isTouched = i == safeTouchedIndex;
      final value = entries[i].value;
      final color = _getCategoryColor(entries[i].key);

      return PieChartSectionData(
        color: isTouched ? color : color.withValues(alpha: 0.85),
        value: value,
        title: '',
        showTitle: false,
        radius: isTouched ? touchedRadius : baseRadius,
        borderSide: isTouched
            ? BorderSide(
                color: Colors.white.withValues(alpha: 0.7),
                width: 2.5,
              )
            : BorderSide.none,
      );
    });
  }

  /// Stable, index-based category→color mapping so adjacent slices always
  /// get maximally distinct colours. Rebuilt when the expense/income toggle
  /// changes because the data set (and therefore entries) change too.
  final Map<String, int> _categoryIndexMap = {};

  Color _getCategoryColor(String categoryId) {
    final colors = showExpense
        ? AppColors.chartPaletteExpense
        : AppColors.chartPaletteIncome;
    // Assign a sequential index the first time we see a category
    if (!_categoryIndexMap.containsKey(categoryId)) {
      _categoryIndexMap[categoryId] = _categoryIndexMap.length;
    }
    return colors[_categoryIndexMap[categoryId]! % colors.length];
  }

  String _categoryDisplayName(String categoryId, Map<String, String> catMap) {
    if (catMap.containsKey(categoryId)) {
      return catMap[categoryId]!;
    }
    var name = categoryId;
    if (name.startsWith('cat_')) name = name.substring(4);
    if (name.isEmpty) return categoryId;
    name = name.replaceAll('_', ' ');
    return name[0].toUpperCase() + name.substring(1);
  }

  Widget _buildChart(Map<String, double> categoryData,
      Map<String, String> catMap, int safeTouchedIndex) {
    final entries = categoryData.entries.toList();
    final total = _getTotal(categoryData);
    final settings = ref.read(settingsProvider);
    final currency = (settings['currency'] as String?) ?? '\u09F3';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final centerRadius = widget.compact ? 44.0 : 56.0;

    // Build the pie chart
    final chart = PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (event, response) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  response?.touchedSection == null) {
                touchedIndex = -1;
                return;
              }
              touchedIndex = response!.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2.5,
        centerSpaceRadius: centerRadius,
        sections: _getSections(
          categoryData,
          widget.compact ? 42 : 48,
          widget.compact ? 52 : 60,
          safeTouchedIndex,
        ),
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );

    // Center display content
    final hasTouched = safeTouchedIndex >= 0;
    final touchedPct = hasTouched && total > 0
        ? (entries[safeTouchedIndex].value / total * 100)
        : 0.0;
    final touchedAmount = hasTouched ? entries[safeTouchedIndex].value : total;
    final touchedColor = hasTouched
        ? _getCategoryColor(entries[safeTouchedIndex].key)
        : Theme.of(context).colorScheme.primary;
    final touchedName = hasTouched
        ? _categoryDisplayName(entries[safeTouchedIndex].key, catMap)
        : context.t('total');

    Widget centerWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: Container(
        key: ValueKey(safeTouchedIndex),
        width: centerRadius * 1.7,
        height: centerRadius * 1.7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.9)),
              (isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.white.withValues(alpha: 0.4)),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasTouched) ...[
              // Percentage
              Text(
                '${touchedPct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: widget.compact ? 18 : 22,
                  fontWeight: FontWeight.w900,
                  color: touchedColor,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              // Amount in TK
              Text(
                '$currency${_formatAmount(touchedAmount)}',
                style: TextStyle(
                  fontSize: widget.compact ? 10 : 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 1),
              // Category name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  touchedName,
                  style: TextStyle(
                    fontSize: widget.compact ? 7 : 8,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              // Default: show total
              Text(
                '$currency${_formatAmount(total)}',
                style: TextStyle(
                  fontSize: widget.compact ? 16 : 19,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.t('total'),
                style: TextStyle(
                  fontSize: widget.compact ? 9 : 10,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.45),
                  height: 1.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.85 + (0.15 * _animation.value),
          child: Opacity(
            opacity: _animation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: SizedBox(
        height: widget.compact ? 190 : 235,
        child: Stack(
          alignment: Alignment.center,
          children: [chart, centerWidget],
        ),
      ),
    );
  }

  Widget _buildLegendSection(Map<String, double> categoryData,
      Map<String, String> catMap, int safeTouchedIndex) {
    final total = _getTotal(categoryData);
    final entries = categoryData.entries.toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.take(6).toList().asMap().entries.map((mapEntry) {
        final i = mapEntry.key;
        final entry = mapEntry.value;
        final color = _getCategoryColor(entry.key);
        final name = _categoryDisplayName(entry.key, catMap);
        final pct = total > 0 ? (entry.value / total * 100) : 0.0;
        final isActive = i == safeTouchedIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: isDark ? 0.2 : 0.1)
                : isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.4)
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                name,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyChart() {
    return SizedBox(
      height: widget.compact ? 80 : 180,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 36,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.2),
            ),
            const SizedBox(height: 8),
            Text(
              context.t(
                'no_type_data',
                params: {
                  'type':
                      showExpense ? context.t('expense') : context.t('income')
                },
              ),
              style: AppTextStyles.body2.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format amount: 1234.5 → 1,235 or 12345 → 12.3K etc.
  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 100000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else if (amount >= 10000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
