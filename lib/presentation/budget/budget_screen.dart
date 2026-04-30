import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/l10n/app_l10n.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../providers/app_providers.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  DateTime _selectedMonth = DateTime.now();
  String? _lastScheduledRolloverKey;

  @override
  Widget build(BuildContext context) {
    final budgets = ref.watch(budgetsProvider);
    final categories = ref.watch(categoriesProvider);
    final settings = ref.watch(settingsProvider);
    final rawCurrency = (settings['currency'] as String?)?.trim();
    final currency = (rawCurrency == null ||
            rawCurrency.isEmpty ||
            rawCurrency == '?' ||
            rawCurrency == 'à§³')
        ? '৳'
        : rawCurrency;
    final rolloverEnabled = settings['rolloverBudget'] == true;

    final budgetCategories = categories
        .where((c) =>
            !c.isDeleted &&
            (c.type == CategoryType.expense || c.type == CategoryType.both))
        .toList();

    _scheduleRolloverIfNeeded(enabled: rolloverEnabled);

    final monthBudgets = _getMonthBudgets(budgets);
    final totalBudget =
        monthBudgets.fold<double>(0, (sum, b) => sum + b.amount);
    final totalSpent = monthBudgets.fold<double>(0, (sum, b) => sum + b.spent);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.t('budget')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showBudgetDialog(
              currency: currency,
              categories: budgetCategories,
              rolloverEnabled: rolloverEnabled,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          _buildOverviewCard(totalBudget, totalSpent, currency),
          Expanded(
            child: monthBudgets.isEmpty
                ? _buildEmptyState(
                    currency: currency,
                    categories: budgetCategories,
                    rolloverEnabled: rolloverEnabled,
                  )
                : _buildBudgetList(
                    budgets: monthBudgets,
                    currency: currency,
                    categories: budgetCategories,
                    rolloverEnabled: rolloverEnabled,
                  ),
          ),
        ],
      ),
    );
  }

  void _scheduleRolloverIfNeeded({required bool enabled}) {
    final month = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final key = '${month.year}-${month.month}-${enabled ? 'on' : 'off'}';
    if (_lastScheduledRolloverKey == key) return;
    _lastScheduledRolloverKey = key;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(budgetsProvider.notifier).ensureMonthlyRollover(
            targetMonth: _selectedMonth,
            enabled: enabled,
          );
    });
  }

  List<BudgetModel> _getMonthBudgets(List<BudgetModel> budgets) {
    return budgets
        .where((budget) =>
            budget.month.year == _selectedMonth.year &&
            budget.month.month == _selectedMonth.month)
        .toList();
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
      double totalBudget, double totalSpent, String currency) {
    final percentage = totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;
    final remaining = totalBudget - totalSpent;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.t('total_budget'),
                style: AppTextStyles.body1.copyWith(color: Colors.white70),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: remaining >= 0
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.error.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$currency${remaining.toStringAsFixed(0)} ${remaining >= 0 ? context.t('remaining') : context.t('over')}',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$currency${totalBudget.toStringAsFixed(0)}',
            style: AppTextStyles.amountLarge.copyWith(
              color: Colors.white,
              fontSize: 34,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage.clamp(0.0, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: percentage >= 1.0 ? AppColors.error : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currency${totalSpent.toStringAsFixed(0)} ${context.t('spent')}',
                style: AppTextStyles.body2.copyWith(color: Colors.white70),
              ),
              Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.body2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetList({
    required List<BudgetModel> budgets,
    required String currency,
    required List<CategoryModel> categories,
    required bool rolloverEnabled,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: budgets.length,
      itemBuilder: (context, index) {
        final budget = budgets[index];
        return _buildBudgetCard(
          budget: budget,
          currency: currency,
          categories: categories,
          rolloverEnabled: rolloverEnabled,
        );
      },
    );
  }

  Widget _buildBudgetCard({
    required BudgetModel budget,
    required String currency,
    required List<CategoryModel> categories,
    required bool rolloverEnabled,
  }) {
    final percentage = budget.amount > 0 ? (budget.spent / budget.amount) : 0.0;
    final remaining = budget.amount - budget.spent;
    final isOverBudget = remaining < 0;

    CategoryModel? category;
    for (final c in categories) {
      if (c.id == budget.categoryId) {
        category = c;
        break;
      }
    }

    final categoryName = category?.name ?? budget.categoryId;
    final categoryIcon = category?.icon ?? 'C';

    Color getProgressColor() {
      if (isOverBudget) return AppColors.error;
      if (percentage >= 0.8) return AppColors.warning;
      return AppColors.success;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverBudget
              ? AppColors.error.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: getProgressColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          categoryIcon,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoryName,
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$currency${budget.amount.toStringAsFixed(0)} ${context.t('budget')}',
                            style: AppTextStyles.caption.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: getProgressColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$currency${remaining.abs().toStringAsFixed(0)} ${isOverBudget ? context.t('over') : context.t('remaining')}',
                      style: AppTextStyles.caption.copyWith(
                        color: getProgressColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _showBudgetDialog(
                          currency: currency,
                          categories: categories,
                          rolloverEnabled: rolloverEnabled,
                          existing: budget,
                        );
                      } else if (value == 'delete') {
                        await _deleteBudget(budget);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 'edit', child: Text(context.t('edit'))),
                      PopupMenuItem(
                          value: 'delete', child: Text(context.t('delete'))),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.more_vert),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: getProgressColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: getProgressColor(),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currency${budget.spent.toStringAsFixed(0)} ${context.t('spent')}',
                style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: getProgressColor(),
                ),
              ),
            ],
          ),
          // Rollover indicator
          if (rolloverEnabled && budget.rollover && budget.rolledAmount > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF0891B2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF0891B2).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.replay_rounded, size: 14, color: Color(0xFF0891B2)),
                  const SizedBox(width: 6),
                  Text(
                    'Rollover: +$currency${budget.rolledAmount.toStringAsFixed(0)}',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF0891B2),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
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

  Widget _buildEmptyState({
    required String currency,
    required List<CategoryModel> categories,
    required bool rolloverEnabled,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: constraints.maxHeight * 0.12),
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 80,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  context.t('no_budgets_month'),
                  style: AppTextStyles.h5.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.t('create_first_budget'),
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showBudgetDialog(
                    currency: currency,
                    categories: categories,
                    rolloverEnabled: rolloverEnabled,
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(context.t('create_budget')),
                ),
                const SizedBox(height: 140),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showBudgetDialog({
    required String currency,
    required List<CategoryModel> categories,
    required bool rolloverEnabled,
    BudgetModel? existing,
  }) async {
    if (categories.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('create_expense_category_first'))),
      );
      return;
    }

    final transactions = ref.read(transactionsProvider);
    final amountController = TextEditingController(
      text: existing == null ? '' : existing.amount.toStringAsFixed(0),
    );
    String? selectedCategoryId = existing?.categoryId;
    double? suggestedAmount;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null
            ? context.t('create_budget')
            : context.t('edit_budget')),
        content: StatefulBuilder(
          builder: (context, setLocalState) {
            void refreshSuggestion() {
              if (selectedCategoryId == null) {
                suggestedAmount = null;
                return;
              }
              suggestedAmount = _calculateSuggestedBudget(
                selectedCategoryId!,
                _selectedMonth,
                transactions,
              );
              if (suggestedAmount != null && suggestedAmount! <= 0) {
                suggestedAmount = null;
              }
            }

            refreshSuggestion();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: context.t('category'),
                    border: const OutlineInputBorder(),
                  ),
                  items: categories
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(cat.icon),
                              const SizedBox(width: 8),
                              Text(
                                cat.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: existing == null
                      ? (value) {
                          selectedCategoryId = value;
                          setLocalState(refreshSuggestion);
                        }
                      : null,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: context.t('budget_amount'),
                    prefixText: '$currency ',
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (existing == null && suggestedAmount != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.t('suggested_amount', params: {
                            'amount':
                                '$currency${suggestedAmount!.toStringAsFixed(0)}'
                          }),
                          style: AppTextStyles.caption,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          amountController.text =
                              suggestedAmount!.toStringAsFixed(0);
                        },
                        child: Text(context.t('use')),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              if (selectedCategoryId == null || amount == null || amount <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                      content: Text(context.t('enter_valid_category_amount'))),
                );
                return;
              }

              final budgetsNotifier = ref.read(budgetsProvider.notifier);
              if (existing == null) {
                final budget = BudgetModel(
                  id: 'budget_${DateTime.now().millisecondsSinceEpoch}',
                  categoryId: selectedCategoryId!,
                  amount: amount,
                  month: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
                  rollover: rolloverEnabled,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                await budgetsNotifier.addBudget(budget);
              } else {
                final updated = existing.copyWith(
                  amount: amount,
                  month: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
                  rollover: rolloverEnabled,
                  updatedAt: DateTime.now(),
                );
                await budgetsNotifier.updateBudget(updated);
              }

              if (!mounted || !dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text(
                    existing == null
                        ? context.t('budget_created_success')
                        : context.t('budget_updated_success'),
                  ),
                ),
              );
            },
            child: Text(
                existing == null ? context.t('create') : context.t('update')),
          ),
        ],
      ),
    );
  }

  double? _calculateSuggestedBudget(
    String categoryId,
    DateTime targetMonth,
    List<TransactionModel> transactions,
  ) {
    double total = 0;
    for (int i = 1; i <= 3; i++) {
      final month = DateTime(targetMonth.year, targetMonth.month - i, 1);
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0);
      final monthTotal = transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.categoryId == categoryId &&
              !t.isDeleted &&
              t.date.isAfter(start.subtract(const Duration(days: 1))) &&
              t.date.isBefore(end.add(const Duration(days: 1))))
          .fold<double>(0, (sum, t) => sum + t.amount);
      total += monthTotal;
    }
    return total / 3;
  }

  Future<void> _deleteBudget(BudgetModel budget) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.t('delete_budget')),
            content: Text(context.t('delete_budget_confirm')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.t('cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: Text(context.t('delete')),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    await ref.read(budgetsProvider.notifier).deleteBudget(budget.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('budget_deleted'))),
    );
  }
}
