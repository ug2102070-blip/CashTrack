import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/debt_model.dart';
import '../../services/notification_service.dart';
import '../providers/app_providers.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  static const _defaultCurrency = '৳';

  @override
  Widget build(BuildContext context) {
    final debts = ref.watch(debtsProvider);
    final settings = ref.watch(settingsProvider);
    final currency = _currencyFromSettings(settings);

    final sorted = [...debts]..sort((a, b) {
        if (a.isSettled != b.isSettled) {
          return a.isSettled ? 1 : -1;
        }
        final aDue = a.dueDate ?? DateTime(9999);
        final bDue = b.dueDate ?? DateTime(9999);
        return aDue.compareTo(bDue);
      });

    final totalToReceive = sorted
        .where((d) => d.type == DebtType.lent && !d.isSettled)
        .fold<double>(0, (s, d) => s + (d.amount - d.paidAmount));
    final totalToPay = sorted
        .where((d) => d.type == DebtType.borrowed && !d.isSettled)
        .fold<double>(0, (s, d) => s + (d.amount - d.paidAmount));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('debts_loans')),
        actions: [
          IconButton(
            onPressed: _openDebtForm,
            icon: const Icon(Icons.add),
            tooltip: context.t('add_debt_loan'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummary(currency, totalToReceive, totalToPay),
          Expanded(
            child: sorted.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final debt = sorted[index];
                      return _buildDebtCard(currency, debt);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(String currency, double toReceive, double toPay) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryTile(
              context.t('to_receive'),
              '$currency${toReceive.toStringAsFixed(0)}',
              AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryTile(
              context.t('to_pay'),
              '$currency${toPay.toStringAsFixed(0)}',
              AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0.09),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: color.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(String currency, DebtModel debt) {
    final remaining = (debt.amount - debt.paidAmount).clamp(0.0, debt.amount);
    final isLent = debt.type == DebtType.lent;
    final dueText = debt.dueDate == null
        ? context.t('no_due_date')
        : DateFormat('dd MMM yyyy').format(debt.dueDate!);
    final color = isLent ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  debt.personName,
                  style:
                      AppTextStyles.body1.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '$currency${debt.amount.toStringAsFixed(0)}',
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (debt.isSettled) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child:
                      Text(context.t('settled'), style: AppTextStyles.caption),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.t(
              'debt_due_line',
              params: {
                'type': isLent
                    ? context.t('will_receive')
                    : context.t('need_to_pay'),
                'date': dueText,
              },
            ),
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 8),
          Text(
            context.t(
              'remaining_amount',
              params: {
                'amount': '$currency${remaining.toStringAsFixed(0)}',
              },
            ),
            style: AppTextStyles.body1.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            context.t(
              'paid_of_total',
              params: {
                'paid': '$currency${debt.paidAmount.toStringAsFixed(0)}',
                'total': debt.amount.toStringAsFixed(0),
              },
            ),
            style: AppTextStyles.caption,
          ),
          if (debt.note?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              debt.note ?? '',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed:
                    debt.isSettled ? null : () => _openPaymentDialog(debt),
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: Text(context.t('payment')),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: () => _openDebtForm(existing: debt),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(context.t('edit')),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _deleteDebt(debt.id),
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.handshake_outlined,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.t('no_debt_records'),
              style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              context.t('track_debt_tip'),
              textAlign: TextAlign.center,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openDebtForm,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.t('add_debt_or_loan')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDebt(String id) async {
    final debt = ref.read(debtsProvider).firstWhere(
          (d) => d.id == id,
          orElse: () => DebtModel(
            id: id,
            type: DebtType.lent,
            personName: '',
            amount: 0,
          ),
        );

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(context.t('delete')),
            content: const Text('Delete this debt record?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.t('cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: Text(context.t('delete')),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    await _cancelDebtReminder(debt);
    await ref.read(debtsProvider.notifier).deleteDebt(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('record_deleted'))),
    );
  }

  Future<void> _openPaymentDialog(DebtModel debt) async {
    final controller = TextEditingController();
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(context.t('add_payment')),
              content: TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: context.t('amount_paid'),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.pop(dialogContext),
                  child: Text(context.t('cancel')),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final add =
                              double.tryParse(controller.text.trim()) ?? 0;
                          if (add <= 0) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(context.t('enter_valid_amount')),
                              ),
                            );
                            return;
                          }

                          setState(() => isSaving = true);

                          final newPaid =
                              (debt.paidAmount + add).clamp(0.0, debt.amount);
                          await ref
                              .read(debtsProvider.notifier)
                              .updatePayment(debt.id, newPaid);
                          if (newPaid >= debt.amount) {
                            await _cancelDebtReminder(debt);
                          }
                          if (!dialogContext.mounted) return;

                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(context.t('payment_added_success')),
                            ),
                          );
                          Navigator.pop(dialogContext);
                        },
                  child: Text(context.t('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openDebtForm({DebtModel? existing}) async {
    final settings = ref.read(settingsProvider);
    final currency = _currencyFromSettings(settings);

    final personController =
        TextEditingController(text: existing?.personName ?? '');
    final amountController = TextEditingController(
      text: existing == null ? '' : existing.amount.toStringAsFixed(0),
    );
    final noteController = TextEditingController(text: existing?.note ?? '');
    DebtType type = existing?.type ?? DebtType.lent;
    DateTime? dueDate = existing?.dueDate;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null
                        ? context.t('add_debt_loan')
                        : context.t('edit_debt_loan'),
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.t('debt_form_hint'),
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<DebtType>(
                    initialValue: type,
                    items: [
                      DropdownMenuItem(
                        value: DebtType.lent,
                        child: Text(context.t('someone_owes_me')),
                      ),
                      DropdownMenuItem(
                        value: DebtType.borrowed,
                        child: Text(context.t('i_owe_someone')),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => type = value);
                      }
                    },
                    decoration: InputDecoration(labelText: context.t('type')),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: personController,
                    decoration:
                        InputDecoration(labelText: context.t('person_name')),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: context.t('total_amount'),
                      prefixText: '$currency ',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(labelText: context.t('note')),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.t('due_date'),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dueDate == null
                                    ? context.t('not_set')
                                    : DateFormat('dd MMM yyyy')
                                        .format(dueDate!),
                                style: AppTextStyles.body1,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dueDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2101),
                              useRootNavigator: true,
                            );
                            if (picked != null) {
                              setModalState(() => dueDate = picked);
                            }
                          },
                        ),
                        if (dueDate != null)
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            tooltip: context.t('clear_date'),
                            onPressed: () =>
                                setModalState(() => dueDate = null),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: StatefulBuilder(
                      builder: (context, setButtonState) {
                        return ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final person = personController.text.trim();
                                  final amount = double.tryParse(
                                    amountController.text.trim(),
                                  );
                                  if (person.isEmpty ||
                                      amount == null ||
                                      amount <= 0) {
                                    ScaffoldMessenger.of(sheetContext)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          context
                                              .t('enter_valid_person_amount'),
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setButtonState(() => isSaving = true);

                                  final clampedPaidAmount = existing == null
                                      ? 0.0
                                      : existing.paidAmount.clamp(0.0, amount);
                                  final isSettled = clampedPaidAmount >= amount;

                                  final debt = (existing ??
                                          DebtModel(
                                            id: DateTime.now()
                                                .millisecondsSinceEpoch
                                                .toString(),
                                            type: type,
                                            personName: person,
                                            amount: amount,
                                          ))
                                      .copyWith(
                                    type: type,
                                    personName: person,
                                    amount: amount,
                                    dueDate: dueDate,
                                    note: noteController.text.trim().isEmpty
                                        ? null
                                        : noteController.text.trim(),
                                    createdAt:
                                        existing?.createdAt ?? DateTime.now(),
                                    updatedAt: DateTime.now(),
                                    paidAmount: clampedPaidAmount,
                                    isSettled: isSettled,
                                  );

                                  if (existing == null) {
                                    await ref
                                        .read(debtsProvider.notifier)
                                        .addDebt(debt);
                                  } else {
                                    await ref
                                        .read(debtsProvider.notifier)
                                        .updateDebt(debt);
                                    await _cancelDebtReminder(existing);
                                  }

                                  await _scheduleDebtReminder(debt);

                                  if (!sheetContext.mounted) return;
                                  ScaffoldMessenger.of(sheetContext)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        existing == null
                                            ? context.t('debt_added_success')
                                            : context.t('debt_updated_success'),
                                      ),
                                    ),
                                  );
                                  Navigator.pop(sheetContext);
                                },
                          child: Text(
                            existing == null
                                ? context.t('add')
                                : context.t('update'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _scheduleDebtReminder(DebtModel debt) async {
    if (kIsWeb) return;
    if (debt.dueDate == null || debt.isSettled) return;
    await NotificationService().scheduleDebtReminder(
      debtId: debt.id,
      personName: debt.personName,
      dueDate: debt.dueDate!,
      amount: debt.amount - debt.paidAmount,
      isBorrowed: debt.type == DebtType.borrowed,
    );
  }

  Future<void> _cancelDebtReminder(DebtModel debt) async {
    if (kIsWeb) return;
    await NotificationService().cancelDebtReminder(debt.id);
  }

  String _currencyFromSettings(Map<String, dynamic> settings) {
    final value = (settings['currency'] as String?)?.trim();
    if (value == null || value.isEmpty || value == '?' || value == 'à§³') {
      return _defaultCurrency;
    }
    return value;
  }
}
