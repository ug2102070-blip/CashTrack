// lib/presentation/dashboard/widgets/transaction_list_dynamic.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/amount_mask.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/app_providers.dart';

class TransactionListDynamic extends ConsumerWidget {
  final List<TransactionModel> transactions;
  final String currency;
  final bool hideAmounts;

  const TransactionListDynamic({
    super.key,
    required this.transactions,
    required this.currency,
    required this.hideAmounts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final catMap = {for (final c in categories) c.id: c.name};
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final compact = false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.t('recent_transactions'),
                  style: AppTextStyles.h5.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/transactions'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                  ),
                  child: Text(
                    context.t('view_all'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (transactions.isEmpty)
            _buildEmptyState(context)
          else
            ...List.generate(
              transactions.take(5).length,
              (i) {
                final t = transactions.take(5).toList()[i];
                final isLast = i == transactions.take(5).length - 1;
                return Column(
                  children: [
                    _buildTransaction(context, t, catMap, compact),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Divider(
                          height: 1,
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                );
              },
            ),

          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildTransaction(BuildContext context, TransactionModel transaction,
      Map<String, String> catMap, bool compact) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.success : AppColors.error;
    final bgColor = color.withValues(alpha: 0.1);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 9 : 13,
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: compact ? 36 : 44,
            height: compact ? 36 : 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(compact ? 10 : 13),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: compact ? 16 : 19,
            ),
          ),
          SizedBox(width: compact ? 10 : 13),
          // Title & date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _categoryDisplayName(transaction.categoryId, catMap),
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 13 : 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(context, transaction.date),
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatSignedAmount(
                  currency,
                  isIncome ? transaction.amount : -transaction.amount,
                  hide: hideAmounts,
                ),
                style: AppTextStyles.body2.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isIncome ? context.t('income') : context.t('expense'),
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(date.year, date.month, date.day);

    if (txDate == today) return context.t('today');
    if (txDate == today.subtract(const Duration(days: 1))) {
      return context.t('yesterday');
    }
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Convert a categoryId like 'cat_salary' -> 'Salary'
  String _categoryDisplayName(String categoryId, Map<String, String> catMap) {
    if (catMap.containsKey(categoryId)) {
      return catMap[categoryId]!;
    }
    String name = categoryId;
    if (name.startsWith('cat_')) name = name.substring(4);
    return name.isEmpty
        ? categoryId
        : name[0].toUpperCase() + name.substring(1).replaceAll('_', ' ');
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 28,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.t('no_transactions_yet'),
              style: AppTextStyles.body2.copyWith(
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
}
