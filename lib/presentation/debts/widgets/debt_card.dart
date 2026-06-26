import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/debt_model.dart';

class DebtCard extends StatelessWidget {
  final DebtModel debt;
  final String currency;
  final VoidCallback onPayment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewAgreement;
  final VoidCallback onSendReminder;
  final VoidCallback? onAddPenalty;

  const DebtCard({
    super.key, required this.debt, required this.currency,
    required this.onPayment, required this.onEdit, required this.onDelete,
    required this.onViewAgreement, required this.onSendReminder,
    this.onAddPenalty,
  });

  @override
  Widget build(BuildContext context) {
    final isLent = debt.type == DebtType.lent;
    final color = isLent ? AppColors.success : AppColors.error;
    final progress = debt.amount > 0 ? (debt.paidAmount / debt.amount).clamp(0.0, 1.0) : 0.0;
    final deadlineInfo = _getDeadlineInfo(context);
    final penalty = debt.penaltyAmount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: debt.isSettled
              ? AppColors.success.withValues(alpha: 0.3)
              : deadlineInfo.isOverdue
                  ? AppColors.error.withValues(alpha: 0.3)
                  : Theme.of(context).dividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: (deadlineInfo.isOverdue ? AppColors.error : Colors.black)
                .withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLent ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: color, size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(debt.personName, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w700)),
              if (debt.phoneNumber?.isNotEmpty == true)
                Text(debt.phoneNumber!, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$currency${debt.amount.toStringAsFixed(0)}',
                style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w700, color: color)),
            if (debt.isSettled) _statusBadge(context, context.t('settled'), AppColors.success)
            else if (debt.hasAgreement) _statusBadge(context, _agreementLabel(context), _agreementColor()),
          ]),
        ]),
        const SizedBox(height: 10),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
            child: Text(context.t('paid_of_total', params: {
              'paid': '$currency${debt.paidAmount.toStringAsFixed(0)}',
              'total': debt.amount.toStringAsFixed(0),
            }), style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
          ),
          Text('${(progress * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: color)),
        ]),

        // Deadline countdown
        if (!debt.isSettled) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: deadlineInfo.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(deadlineInfo.icon, size: 15, color: deadlineInfo.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(deadlineInfo.text, style: AppTextStyles.caption.copyWith(
                    color: deadlineInfo.color, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
              if (debt.dueDate != null)
                Text(DateFormat('dd MMM yyyy').format(debt.dueDate!),
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ]),
          ),
        ],

        // Penalty info (user-added manual penalty)
        if (penalty > 0 && !debt.isSettled) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, size: 15, color: AppColors.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text('${context.t('penalty_amount')}: $currency${penalty.toStringAsFixed(0)}',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.error, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        ],

        // Trust score
        if (debt.hasAgreement && !debt.isSettled) ...[
          const SizedBox(height: 6),
          _buildTrustScore(context),
        ],

        // Note
        if (debt.note?.isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text(debt.note!, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        ],

        // Actions - using Wrap to prevent overflow
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 6,
          children: [
            if (!debt.isSettled)
              _actionBtn(context, Icons.payments_outlined, context.t('payment'), onPayment),
            if (debt.hasAgreement)
              _actionBtn(context, Icons.description_outlined, context.t('view_agreement'), onViewAgreement),
            if (!debt.isSettled && isLent)
              _actionBtn(context, Icons.notifications_active_outlined, context.t('send_reminder'), onSendReminder),
            if (!debt.isSettled && deadlineInfo.isOverdue && onAddPenalty != null)
              _actionBtn(context, Icons.add_alert_rounded, context.t('add_penalty'), onAddPenalty!,
                  accentColor: AppColors.error),
          ],
        ),
        // Edit/Delete row
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.textSecondary, visualDensity: VisualDensity.compact),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.error, visualDensity: VisualDensity.compact),
          ],
        ),
      ]),
    );
  }

  Widget _actionBtn(BuildContext context, IconData icon, String label, VoidCallback onTap,
      {Color? accentColor}) {
    final btnColor = accentColor ?? Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: accentColor != null
              ? accentColor.withValues(alpha: 0.4)
              : Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
          color: accentColor?.withValues(alpha: 0.05),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: btnColor),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.caption.copyWith(
              color: btnColor, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _statusBadge(BuildContext context, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(
          color: color, fontWeight: FontWeight.w600, fontSize: 10)),
    );
  }

  Widget _buildTrustScore(BuildContext context) {
    final score = debt.trustScore.clamp(0, 100);
    final Color tsColor;
    final String tsLabel;
    if (score >= 80) { tsColor = AppColors.success; tsLabel = context.t('trust_excellent'); }
    else if (score >= 60) { tsColor = const Color(0xFF22C55E); tsLabel = context.t('trust_good'); }
    else if (score >= 40) { tsColor = AppColors.warning; tsLabel = context.t('trust_average'); }
    else if (score >= 20) { tsColor = const Color(0xFFF97316); tsLabel = context.t('trust_poor'); }
    else { tsColor = AppColors.error; tsLabel = context.t('trust_very_poor'); }

    return Row(children: [
      Icon(Icons.verified_user_outlined, size: 14, color: tsColor),
      const SizedBox(width: 4),
      Flexible(
        child: Text('${context.t('trust_score')}: $score', style: AppTextStyles.caption.copyWith(
            color: tsColor, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
      ),
      const SizedBox(width: 6),
      Text('($tsLabel)', style: AppTextStyles.caption.copyWith(color: tsColor)),
      const Spacer(),
      SizedBox(
        width: 60, height: 5,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: tsColor.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(tsColor),
          ),
        ),
      ),
    ]);
  }

  String _agreementLabel(BuildContext context) {
    switch (debt.agreementStatus) {
      case AgreementStatus.pending: return context.t('status_pending');
      case AgreementStatus.accepted: return context.t('status_accepted');
      case AgreementStatus.rejected: return context.t('status_rejected');
      case AgreementStatus.expired: return context.t('status_expired');
      case AgreementStatus.completed: return context.t('status_completed');
    }
  }

  Color _agreementColor() {
    switch (debt.agreementStatus) {
      case AgreementStatus.pending: return AppColors.warning;
      case AgreementStatus.accepted: return AppColors.success;
      case AgreementStatus.rejected: return AppColors.error;
      case AgreementStatus.expired: return AppColors.error;
      case AgreementStatus.completed: return AppColors.success;
    }
  }

  _DeadlineInfo _getDeadlineInfo(BuildContext context) {
    if (debt.dueDate == null) {
      return _DeadlineInfo(context.t('no_deadline'), AppColors.textSecondary, Icons.event_outlined, false);
    }
    final now = DateTime.now();
    final diff = debt.dueDate!.difference(now);
    if (diff.isNegative) {
      final days = diff.inDays.abs();
      return _DeadlineInfo(
        context.t('overdue_days', params: {'count': '$days'}),
        AppColors.error, Icons.warning_rounded, true,
      );
    } else if (diff.inDays == 0) {
      return _DeadlineInfo(context.t('deadline_today'), AppColors.warning, Icons.alarm, false);
    } else if (diff.inDays <= 3) {
      return _DeadlineInfo(
        context.t('days_remaining', params: {'count': '${diff.inDays}'}),
        AppColors.warning, Icons.timer_outlined, false,
      );
    } else {
      return _DeadlineInfo(
        context.t('days_remaining', params: {'count': '${diff.inDays}'}),
        AppColors.info, Icons.event_outlined, false,
      );
    }
  }
}

class _DeadlineInfo {
  final String text;
  final Color color;
  final IconData icon;
  final bool isOverdue;
  _DeadlineInfo(this.text, this.color, this.icon, this.isOverdue);
}
