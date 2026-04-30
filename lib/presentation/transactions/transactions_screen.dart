// lib/presentation/transactions/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/l10n/app_l10n.dart';
import '../../data/models/transaction_model.dart';
import '../providers/app_providers.dart';
import 'add_transaction_form.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  TransactionType? _filterType;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider);
    final settings = ref.watch(settingsProvider);
    final currency = (settings['currency'] as String?) ?? '৳';
    final categoryMap = {for (final c in categories) c.id: c.name};
    final filtered = _applyFilters(transactions);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            _buildSummaryBanner(filtered, currency, isDark),
            if (_hasActiveFilters()) _buildFilterChips(context),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(context)
                  : _buildList(filtered, currency, categoryMap, isDark),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.t('transactions'),
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.4,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          _iconBtn(
            context,
            Icons.filter_list_rounded,
            isDark,
            _showFilterSheet,
            hasBadge: _hasActiveFilters(),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(
    BuildContext context,
    IconData icon,
    bool isDark,
    VoidCallback onTap, {
    bool hasBadge = false,
  }) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: hasBadge
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
            ),
          ),
        ),
        if (hasBadge)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // â”€â”€ Summary Banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSummaryBanner(
    List<TransactionModel> txs,
    String currency,
    bool isDark,
  ) {
    final income = txs
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = txs
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (s, t) => s + t.amount);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary,
            Color.lerp(primary, Colors.indigo.shade700, 0.4)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _bannerStat(
              context.t('total_income'),
              '$currency${_fmt(income)}',
              Icons.arrow_downward_rounded,
              Colors.greenAccent.shade100,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _bannerStat(
              context.t('total_expense'),
              '$currency${_fmt(expense)}',
              Icons.arrow_upward_rounded,
              Colors.red.shade100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerStat(
    String label,
    String value,
    IconData icon,
    Color valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // â”€â”€ Filter chips â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildFilterChips(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (_filterType != null)
            Chip(
              label: Text(_typeLabel(context, _filterType!)),
              deleteIcon: const Icon(Icons.close_rounded, size: 14),
              onDeleted: () => setState(() => _filterType = null),
            ),
          if (_dateRange != null)
            Chip(
              label: Text(
                '${DateFormat('MMM dd').format(_dateRange!.start)} - ${DateFormat('MMM dd').format(_dateRange!.end)}',
              ),
              deleteIcon: const Icon(Icons.close_rounded, size: 14),
              onDeleted: () => setState(() => _dateRange = null),
            ),
        ],
      ),
    );
  }

  // â”€â”€ Transaction List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildList(
    List<TransactionModel> txs,
    String currency,
    Map<String, String> catMap,
    bool isDark,
  ) {
    final grouped = <String, List<TransactionModel>>{};
    for (final t in txs) {
      final key = DateFormat('yyyy-MM-dd').format(t.date);
      grouped[key] = [...(grouped[key] ?? []), t];
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 110),
      physics: const BouncingScrollPhysics(),
      itemCount: grouped.length,
      itemBuilder: (_, i) {
        final key = grouped.keys.elementAt(i);
        final date = DateTime.parse(key);
        final dayTxs = grouped[key]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dateHeader(context, date, dayTxs, currency),
            ...dayTxs.map(
              (t) => _transactionTile(context, t, currency, catMap, isDark),
            ),
          ],
        );
      },
    );
  }

  Widget _dateHeader(
    BuildContext context,
    DateTime date,
    List<TransactionModel> txs,
    String currency,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(date.year, date.month, date.day);
    final label = txDate == today
        ? context.t('today')
        : txDate == today.subtract(const Duration(days: 1))
            ? context.t('yesterday')
            : DateFormat('EEEE, MMM dd').format(date);

    final dayTotal = txs.fold<double>(0, (s, t) {
      return t.type == TransactionType.expense ? s - t.amount : s + t.amount;
    });
    final totalColor = dayTotal >= 0 ? AppColors.success : AppColors.error;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.2,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          Text(
            '${dayTotal >= 0 ? '+' : ''}$currency${_fmt(dayTotal.abs())}',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: totalColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(
    BuildContext context,
    TransactionModel t,
    String currency,
    Map<String, String> catMap,
    bool isDark,
  ) {
    final isIncome = t.type == TransactionType.income;
    final color = isIncome ? AppColors.success : AppColors.error;
    final catName = catMap[t.categoryId] ?? t.categoryId;

    return InkWell(
      onTap: () => _showDetails(context, t, currency, catMap),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isIncome
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    catName,
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (t.note != null && t.note!.isNotEmpty)
                    Text(
                      t.note!,
                      style: AppTextStyles.caption.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      DateFormat('hh:mm a').format(t.date),
                      style: AppTextStyles.caption.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.35),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}$currency${_fmt(t.amount)}',
                  style: AppTextStyles.body2.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    isIncome
                        ? context.t('income_short')
                        : context.t('expense_short'),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 34,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.t('no_transactions_found'),
            style: AppTextStyles.h5.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _hasActiveFilters()
                ? context.t('try_adjust_filters')
                : context.t('add_first_transaction'),
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Filter Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showFilterSheet() {
    final now = DateTime.now();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(context.t('filter'), style: AppTextStyles.h5),
            const SizedBox(height: 16),
            Text(
              context.t('type'),
              style: AppTextStyles.caption.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: Text(context.t('income')),
                  selected: _filterType == TransactionType.income,
                  onSelected: (v) => setState(() {
                    _filterType = v ? TransactionType.income : null;
                    Navigator.pop(ctx);
                  }),
                ),
                FilterChip(
                  label: Text(context.t('expense')),
                  selected: _filterType == TransactionType.expense,
                  onSelected: (v) => setState(() {
                    _filterType = v ? TransactionType.expense : null;
                    Navigator.pop(ctx);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              context.t('date_range'),
              style: AppTextStyles.caption.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.45),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.date_range_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
              ),
              title: Text(
                _dateRange == null
                    ? context.t('select_date_range')
                    : '${DateFormat('MMM dd, yyyy').format(_dateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_dateRange!.end)}',
                style: AppTextStyles.body2,
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: now,
                  initialDateRange: _dateRange,
                );
                if (picked != null) {
                  setState(() => _dateRange = picked);
                }
              },
            ),
            if (_dateRange != null)
              TextButton.icon(
                onPressed: () {
                  setState(() => _dateRange = null);
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.clear_rounded, size: 16),
                label: Text(context.t('clear_date_filter')),
              ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Details Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showDetails(
    BuildContext context,
    TransactionModel t,
    String currency,
    Map<String, String> categoryMap,
  ) {
    final isIncome = t.type == TransactionType.income;
    final color = isIncome ? AppColors.success : AppColors.error;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isIncome
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${isIncome ? '+' : '-'}$currency${t.amount.toStringAsFixed(2)}',
              style: AppTextStyles.amountLarge.copyWith(
                color: color,
                fontSize: 34,
              ),
            ),
            Text(
              categoryMap[t.categoryId] ?? t.categoryId,
              style: AppTextStyles.body1.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
            ),
            if (t.note != null && t.note!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                t.note!,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 6),
            Text(
              DateFormat('EEEE, MMM dd, yyyy - hh:mm a').format(t.date),
              style: AppTextStyles.caption.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openEdit(t);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: Text(context.t('edit')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _delete(t.id);
                    },
                    icon: const Icon(Icons.delete_rounded, size: 18),
                    label: Text(context.t('delete')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEdit(TransactionModel t) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: AddTransactionForm(
            transactionToEdit: t,
            embedded: true,
          ),
        ),
      ),
    );
  }

  Future<void> _delete(String id) async {
    final txs = ref.read(transactionsProvider);
    final t = txs.cast<TransactionModel?>().firstWhere(
          (t) => t?.id == id,
          orElse: () => null,
        );
    if (t == null) return;

    await ref.read(transactionsProvider.notifier).deleteTransaction(id);
    await _syncBudgetOnDelete(t);

    await _syncAccountOnDelete(t);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('transaction_deleted'))),
    );
  }

  Future<void> _syncBudgetOnDelete(TransactionModel t) async {
    if (t.type != TransactionType.expense) return;
    final notifier = ref.read(budgetsProvider.notifier);
    final budget = notifier.getBudgetByCategory(t.categoryId, t.date);
    if (budget == null) return;
    final next = (budget.spent - t.amount).clamp(0.0, double.infinity);
    await notifier.updateSpent(budget.id, next);
  }

  Future<void> _syncAccountOnDelete(TransactionModel t) async {
    final accountsNotifier = ref.read(accountsProvider.notifier);
    final fromAccount = accountsNotifier.getAccountById(t.accountId);

    switch (t.type) {
      case TransactionType.income:
        if (fromAccount != null) {
          await accountsNotifier.updateBalance(
            t.accountId,
            fromAccount.balance - t.amount,
          );
        }
        return;
      case TransactionType.expense:
      case TransactionType.lent:
      case TransactionType.borrowed:
        if (fromAccount != null) {
          await accountsNotifier.updateBalance(
            t.accountId,
            fromAccount.balance + t.amount,
          );
        }
        return;
      case TransactionType.transfer:
        if (fromAccount != null) {
          await accountsNotifier.updateBalance(
            t.accountId,
            fromAccount.balance + t.amount,
          );
        }
        final toAccountId = t.toAccountId;
        if (toAccountId == null || toAccountId.isEmpty) return;
        final toAccount = accountsNotifier.getAccountById(toAccountId);
        if (toAccount != null) {
          await accountsNotifier.updateBalance(
            toAccountId,
            toAccount.balance - t.amount,
          );
        }
        return;
    }
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  List<TransactionModel> _applyFilters(List<TransactionModel> txs) {
    var out = txs;
    if (_filterType != null) {
      out = out.where((t) => t.type == _filterType).toList();
    }
    if (_dateRange != null) {
      out = out.where((t) {
        return t.date
                .isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
            t.date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  bool _hasActiveFilters() => _filterType != null || _dateRange != null;

  String _typeLabel(BuildContext context, TransactionType t) =>
      t == TransactionType.income ? context.t('income') : context.t('expense');

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
