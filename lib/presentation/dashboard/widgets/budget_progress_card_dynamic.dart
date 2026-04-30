// lib/presentation/dashboard/widgets/budget_progress_card_dynamic.dart
import 'package:flutter/material.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class BudgetProgressCardDynamic extends StatelessWidget {
  final double spent;
  final double budget;
  final String currency;

  const BudgetProgressCardDynamic({
    super.key,
    required this.spent,
    required this.budget,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (budget > 0) ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Text(context.t('monthly_budget'), style: AppTextStyles.h3),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.body2
                    .copyWith(color: primaryColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: primaryColor.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            borderRadius: BorderRadius.circular(10),
            minHeight: 10,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBudgetInfo(context.t('spent'), spent, AppColors.error),
              _buildBudgetInfo(
                  context.t('remaining'), (budget - spent), AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetInfo(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        Text(
          '$currency ${amount.toStringAsFixed(0)}',
          style: AppTextStyles.body1
              .copyWith(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
