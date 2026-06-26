import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/debt_model.dart';

class AgreementViewSheet extends StatelessWidget {
  final DebtModel debt;
  final String currency;
  const AgreementViewSheet({super.key, required this.debt, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isLent = debt.type == DebtType.lent;
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
            color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          // Header
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Column(children: [
              Icon(Icons.gavel_rounded, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 6),
              Text(context.t('agreement_contract'), style: AppTextStyles.h5.copyWith(
                  fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
            ]),
          ),
          const SizedBox(height: 16),
          // Parties
          _row(context, context.t('lender'), isLent ? context.t('me') : debt.personName),
          _row(context, context.t('borrower'), isLent ? debt.personName : context.t('me')),
          if (debt.phoneNumber?.isNotEmpty == true)
            _row(context, context.t('phone_number_optional').replaceAll(' (Optional)', '').replaceAll(' (ঐচ্ছিক)', ''), debt.phoneNumber!),
          _divider(),
          _row(context, context.t('principal_amount'), '$currency${debt.amount.toStringAsFixed(0)}'),
          if (debt.dueDate != null)
            _row(context, context.t('agreed_deadline'), DateFormat('dd MMM yyyy').format(debt.dueDate!)),
          if (debt.paymentMethod?.isNotEmpty == true)
            _row(context, context.t('payment_method'), debt.paymentMethod!),
          _divider(),
          // Penalty clause
          if (debt.penaltyRate > 0) ...[
            Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.t('penalty_clause'), style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.error)),
                const SizedBox(height: 4),
                Text(context.t('daily_penalty_after_deadline',
                    params: {'rate': debt.penaltyRate.toStringAsFixed(1)}),
                    style: AppTextStyles.body2.copyWith(color: AppColors.error)),
              ]),
            ),
            const SizedBox(height: 10),
          ],
          // Terms
          if (debt.agreementTerms?.isNotEmpty == true) ...[
            Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.t('agreement_terms'), style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.info)),
                const SizedBox(height: 4),
                Text(debt.agreementTerms!, style: AppTextStyles.body2),
              ]),
            ),
            const SizedBox(height: 10),
          ],
          // Created date
          if (debt.createdAt != null)
            Text(context.t('agreement_created_on',
                params: {'date': DateFormat('dd MMM yyyy, hh:mm a').format(debt.createdAt!)}),
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          // Copy button
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () {
              final text = _generateAgreementText(context);
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.t('payment_link_copied'))));
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy Agreement Text'),
          )),
        ],
      )),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Divider(color: AppColors.divider.withValues(alpha: 0.5)),
  );

  String _generateAgreementText(BuildContext context) {
    final isLent = debt.type == DebtType.lent;
    final buf = StringBuffer()
      ..writeln('═══ DEBT AGREEMENT ═══')
      ..writeln('Lender: ${isLent ? "Me" : debt.personName}')
      ..writeln('Borrower: ${isLent ? debt.personName : "Me"}')
      ..writeln('Amount: $currency${debt.amount.toStringAsFixed(0)}');
    if (debt.dueDate != null) buf.writeln('Deadline: ${DateFormat('dd MMM yyyy').format(debt.dueDate!)}');
    if (debt.penaltyRate > 0) buf.writeln('Penalty: ${debt.penaltyRate}% daily after deadline');
    if (debt.agreementTerms?.isNotEmpty == true) buf.writeln('Terms: ${debt.agreementTerms}');
    if (debt.paymentMethod?.isNotEmpty == true) buf.writeln('Payment via: ${debt.paymentMethod}');
    buf.writeln('Created: ${DateFormat('dd MMM yyyy').format(debt.createdAt ?? DateTime.now())}');
    buf.writeln('═══════════════════════');
    return buf.toString();
  }
}
