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

class _ExpenseChartDynamicState extends ConsumerState<ExpenseChartDynamic> {
  int touchedIndex = -1;
  bool showExpense = true;

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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                showExpense
                    ? context.t('expense_breakdown')
                    : context.t('income_breakdown'),
                style: AppTextStyles.h5.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              // Compact toggle
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
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
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: categoryData.entries.take(4).map((entry) {
                return _buildLegend(
                  _categoryDisplayName(entry.key, catMap),
                  _getCategoryColor(entry.key),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String text, bool forExpense, Color primary) {
    final isSelected = showExpense == forExpense;
    return GestureDetector(
      onTap: () => setState(() => showExpense = forExpense),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
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
    return data;
  }

  double _getTotal(Map<String, double> data) =>
      data.values.fold(0, (s, a) => s + a);

  List<PieChartSectionData> _getSections(Map<String, double> data,
      double baseRadius, double touchedRadius, int safeTouchedIndex) {
    final total = _getTotal(data);
    final entries = data.entries.toList();
    return List.generate(entries.length, (i) {
      final isTouched = i == safeTouchedIndex;
      final value = entries[i].value;
      final pct = total > 0 ? (value / total * 100) : 0.0;
      return PieChartSectionData(
        color: _getCategoryColor(entries[i].key),
        value: value,
        title: isTouched ? '${pct.toStringAsFixed(0)}%' : '',
        radius: isTouched ? touchedRadius : baseRadius,
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
    });
  }

  Color _getCategoryColor(String categoryId) {
    final colors = showExpense
        ? AppColors.chartPaletteExpense
        : AppColors.chartPaletteIncome;
    return colors[categoryId.hashCode.abs() % colors.length];
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
        sectionsSpace: 3,
        centerSpaceRadius: widget.compact ? 40 : 52,
        sections: _getSections(
          categoryData,
          widget.compact ? 46 : 50,
          widget.compact ? 54 : 58,
          safeTouchedIndex,
        ),
      ),
    );

    // Center label
    final total = _getTotal(categoryData);
    final settings = ref.read(settingsProvider);
    final currency = (settings['currency'] as String?) ?? '\u09F3';

    Widget centerWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          safeTouchedIndex >= 0
              ? '${(total > 0 ? (entries[safeTouchedIndex].value / total * 100) : 0.0).toStringAsFixed(0)}%'
              : '$currency${total.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          safeTouchedIndex >= 0
              ? _categoryDisplayName(entries[safeTouchedIndex].key, catMap)
              : context.t('total'),
          style: TextStyle(
            fontSize: 9,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return SizedBox(
      height: widget.compact ? 180 : 220,
      child: Stack(
        alignment: Alignment.center,
        children: [chart, centerWidget],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
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
}
