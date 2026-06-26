import 'package:flutter/material.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/debt_model.dart';

class DebtSummaryHeader extends StatelessWidget {
  final String currency;
  final List<DebtModel> debts;
  const DebtSummaryHeader({super.key, required this.currency, required this.debts});

  @override
  Widget build(BuildContext context) {
    final active = debts.where((d) => !d.isSettled).toList();
    final totalLent = active.where((d) => d.type == DebtType.lent)
        .fold<double>(0, (s, d) => s + (d.amount - d.paidAmount));
    final totalBorrowed = active.where((d) => d.type == DebtType.borrowed)
        .fold<double>(0, (s, d) => s + (d.amount - d.paidAmount));
    final overdueCount = active.where((d) =>
        d.dueDate != null && d.dueDate!.isBefore(DateTime.now())).length;
    final totalPenalty = active.fold<double>(0, (s, d) => s + d.penaltyAmount);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _tile(context, context.t('total_lent'),
                '$currency${totalLent.toStringAsFixed(0)}', AppColors.success)),
            const SizedBox(width: 10),
            Expanded(child: _tile(context, context.t('total_borrowed'),
                '$currency${totalBorrowed.toStringAsFixed(0)}', AppColors.error)),
          ]),
          if (overdueCount > 0 || totalPenalty > 0) ...[
            const SizedBox(height: 10),
            Row(children: [
              if (overdueCount > 0)
                _chip(context, '⚠️ ${context.t('overdue_count', params: {'count': '$overdueCount'})}',
                    AppColors.warning),
              if (overdueCount > 0 && totalPenalty > 0) const SizedBox(width: 8),
              if (totalPenalty > 0)
                _chip(context, '💰 $currency${totalPenalty.toStringAsFixed(0)} ${context.t('total_penalty')}',
                    AppColors.error),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.caption.copyWith(
            color: color.withValues(alpha: 0.9), fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _chip(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: AppTextStyles.caption.copyWith(
          color: color, fontWeight: FontWeight.w600)),
    );
  }
}
