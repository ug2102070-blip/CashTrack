import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/amount_mask.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/app_providers.dart';

class DailyBudgetTrackerCard extends ConsumerWidget {
  final Map<String, dynamic> settings;
  final String currency;

  const DailyBudgetTrackerCard({
    super.key,
    required this.settings,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyLimit = (settings['dailyBudgetLimit'] as num?)?.toInt() ?? 0;
    if (dailyLimit <= 0) return const SizedBox.shrink();

    final dailyRollover = settings['dailyBudgetRollover'] as bool? ?? false;
    final startDateMs = settings['dailyBudgetStartDate'] as int?;
    final transactions = ref.watch(transactionsProvider);

    int daysPassed = 1;
    int expectedLimit = dailyLimit;
    int totalSpent = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

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
      totalSpent = transactions.where((t) {
        if (t.type != TransactionType.expense || t.isDeleted) return false;
        final txDay = DateTime(t.date.year, t.date.month, t.date.day);
        return txDay.isAtSameMomentAs(today);
      }).fold<int>(0, (sum, t) => sum + t.amount);
    }

    final remaining = expectedLimit - totalSpent;
    final percentage = expectedLimit > 0 ? (totalSpent / expectedLimit).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = remaining < 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color getProgressColor() {
      if (isOverBudget) return AppColors.error;
      if (percentage >= 0.8) return AppColors.warning;
      return AppColors.success;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.today_rounded,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Allowance',
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (dailyRollover && daysPassed > 1)
                        Text(
                          '$daysPassed Days Carry Forward',
                          style: AppTextStyles.caption.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: getProgressColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${formatAmount(currency, remaining.abs(), decimals: 0)} ${isOverBudget ? 'over' : 'left'}',
                  style: AppTextStyles.caption.copyWith(
                    color: getProgressColor(),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatAmount(currency, totalSpent, decimals: 0),
                style: AppTextStyles.amountLarge.copyWith(
                  fontSize: 28,
                  height: 1,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '/ ${formatAmount(currency, expectedLimit, decimals: 0)}',
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: getProgressColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: getProgressColor(),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
