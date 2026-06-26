import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/debt_model.dart';
import '../../services/notification_service.dart';
import '../providers/app_providers.dart';
import 'widgets/debt_summary_header.dart';
import 'widgets/debt_card.dart';
import 'widgets/agreement_view_sheet.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});
  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> with SingleTickerProviderStateMixin {
  static const _defaultCurrency = '৳';
  late TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _tabIndex = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debts = ref.watch(debtsProvider);
    final settings = ref.watch(settingsProvider);
    final currency = _currencyFromSettings(settings);

    final filtered = _filterDebts(debts);
    final sorted = [...filtered]..sort((a, b) {
      if (a.isSettled != b.isSettled) return a.isSettled ? 1 : -1;
      final aDue = a.dueDate ?? DateTime(9999);
      final bDue = b.dueDate ?? DateTime(9999);
      return aDue.compareTo(bDue);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('debts_loans')),
        actions: [
          IconButton(
            onPressed: () => _openDebtForm(currency),
            icon: const Icon(Icons.add_rounded),
            tooltip: context.t('create_agreement'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: context.t('all')),
            Tab(text: context.t('lent_tab')),
            Tab(text: context.t('borrowed_tab')),
            Tab(text: context.t('overdue_tab')),
          ],
        ),
      ),
      body: Column(children: [
        DebtSummaryHeader(currency: currency, debts: debts),
        Expanded(
          child: sorted.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => DebtCard(
                    debt: sorted[i], currency: currency,
                    onPayment: () => _openPaymentDialog(sorted[i]),
                    onEdit: () => _openDebtForm(currency, existing: sorted[i]),
                    onDelete: () => _deleteDebt(sorted[i]),
                    onViewAgreement: () => _showAgreement(sorted[i], currency),
                    onSendReminder: () => _sendReminder(sorted[i], currency),
                    onAddPenalty: () => _openPenaltyDialog(sorted[i], currency),
                  ),
                ),
        ),
      ]),
    );
  }

  List<DebtModel> _filterDebts(List<DebtModel> debts) {
    switch (_tabIndex) {
      case 1: return debts.where((d) => d.type == DebtType.lent).toList();
      case 2: return debts.where((d) => d.type == DebtType.borrowed).toList();
      case 3: return debts.where((d) =>
          !d.isSettled && d.dueDate != null && d.dueDate!.isBefore(DateTime.now())).toList();
      default: return debts;
    }
  }

  Widget _buildEmptyState() {
    return Center(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.handshake_outlined, size: 34, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        Text(context.t('no_debt_records'),
            style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(context.t('track_debt_tip'), textAlign: TextAlign.center,
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _openDebtForm(_currencyFromSettings(ref.read(settingsProvider))),
          icon: const Icon(Icons.add_rounded),
          label: Text(context.t('create_agreement')),
        ),
      ]),
    ));
  }

  // ── ACTIONS ────────────────────────────────────────────

  Future<void> _deleteDebt(DebtModel debt) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('delete')),
        content: const Text('Delete this debt record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.t('cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(context.t('delete')),
          ),
        ],
      ),
    ) ?? false;
    if (!yes) return;
    await _cancelDebtReminder(debt);
    await ref.read(debtsProvider.notifier).deleteDebt(debt.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('record_deleted'))));
  }

  void _showAgreement(DebtModel debt, String currency) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => AgreementViewSheet(debt: debt, currency: currency),
    );
  }

  Future<void> _sendReminder(DebtModel debt, String currency) async {
    final remaining = (debt.amount - debt.paidAmount).clamp(0.0, debt.amount);
    final msg = 'Reminder: You owe $currency${remaining.toStringAsFixed(0)} '
        '${debt.dueDate != null ? "due ${DateFormat('dd MMM').format(debt.dueDate!)}" : ""}. '
        'Please settle soon.';

    if (debt.phoneNumber?.isNotEmpty == true) {
      final smsUri = Uri.parse('sms:${debt.phoneNumber}?body=${Uri.encodeComponent(msg)}');
      try { await launchUrl(smsUri); } catch (_) {}
    } else {
      await Clipboard.setData(ClipboardData(text: msg));
    }

    // Update reminder count
    final updated = debt.copyWith(
      remindersSent: debt.remindersSent + 1,
      lastReminderAt: DateTime.now(),
      trustScore: (debt.trustScore - 2).clamp(0, 100),
    );
    await ref.read(debtsProvider.notifier).updateDebt(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('reminder_sent'))));
  }

  Future<void> _openPaymentDialog(DebtModel debt) async {
    final controller = TextEditingController();
    bool isSaving = false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setState) => AlertDialog(
        title: Text(context.t('add_payment')),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: context.t('amount_paid')),
        ),
        actions: [
          TextButton(onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: Text(context.t('cancel'))),
          ElevatedButton(
            onPressed: isSaving ? null : () async {
              final add = double.tryParse(controller.text.trim()) ?? 0;
              if (add <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(context.t('enter_valid_amount'))));
                return;
              }
              setState(() => isSaving = true);
              final newPaid = (debt.paidAmount + add).clamp(0.0, debt.amount);
              final isFullyPaid = newPaid >= debt.amount;

              // Update trust score: on-time = +5, late = -10
              int newTrust = debt.trustScore;
              if (isFullyPaid) {
                final isOnTime = debt.dueDate == null || !DateTime.now().isAfter(debt.dueDate!);
                newTrust = isOnTime ? (debt.trustScore + 5).clamp(0, 100)
                    : (debt.trustScore - 10).clamp(0, 100);
              }

              final updated = debt.copyWith(
                paidAmount: newPaid,
                isSettled: isFullyPaid,
                trustScore: newTrust,
                agreementStatus: isFullyPaid ? AgreementStatus.completed : debt.agreementStatus,
                updatedAt: DateTime.now(),
              );
              await ref.read(debtsProvider.notifier).updateDebt(updated);
              if (isFullyPaid) await _cancelDebtReminder(debt);
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(context.t('payment_added_success'))));
              Navigator.pop(ctx);
            },
            child: Text(context.t('save')),
          ),
        ],
      )),
    );
  }

  // ── DEBT FORM ──────────────────────────────────────────

  Future<void> _openDebtForm(String currency, {DebtModel? existing}) async {
    final personC = TextEditingController(text: existing?.personName ?? '');
    final amountC = TextEditingController(
        text: existing == null ? '' : existing.amount.toStringAsFixed(0));
    final noteC = TextEditingController(text: existing?.note ?? '');
    final phoneC = TextEditingController(text: existing?.phoneNumber ?? '');
    final termsC = TextEditingController(text: existing?.agreementTerms ?? '');
    final penaltyC = TextEditingController(
        text: existing == null || existing.penaltyRate == 0 ? '' : existing.penaltyRate.toString());

    DebtType type = existing?.type ?? DebtType.lent;
    DateTime? dueDate = existing?.dueDate;
    bool hasAgreement = existing?.hasAgreement ?? false;
    String? paymentMethod = existing?.paymentMethod;

    final paymentMethods = ['bKash', 'Nagad', 'Rocket', 'Bank Transfer', 'Cash'];

    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) {
        bool isSaving = false;
        return StatefulBuilder(builder: (context, setModalState) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(left: 16, right: 16, top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24),
            child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(existing == null ? context.t('create_agreement') : context.t('edit_debt_loan'),
                  style: AppTextStyles.h4),
              const SizedBox(height: 4),
              Text(context.t('debt_form_hint'),
                  style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 14),

              // Type dropdown
              DropdownButtonFormField<DebtType>(
                initialValue: type,
                items: [
                  DropdownMenuItem(value: DebtType.lent, child: Text(context.t('someone_owes_me'))),
                  DropdownMenuItem(value: DebtType.borrowed, child: Text(context.t('i_owe_someone'))),
                ],
                onChanged: (v) { if (v != null) setModalState(() => type = v); },
                decoration: InputDecoration(labelText: context.t('type')),
              ),
              const SizedBox(height: 10),
              TextField(controller: personC,
                  decoration: InputDecoration(labelText: context.t('person_name'),
                      prefixIcon: const Icon(Icons.person_outline))),
              const SizedBox(height: 10),
              TextField(controller: phoneC,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: context.t('phone_number_optional'),
                      prefixIcon: const Icon(Icons.phone_outlined))),
              const SizedBox(height: 10),
              TextField(controller: amountC,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: context.t('total_amount'),
                      prefixText: '$currency ', prefixIcon: const Icon(Icons.money))),
              const SizedBox(height: 10),

              // Due date
              _buildDatePicker(context, dueDate, (d) => setModalState(() => dueDate = d)),
              const SizedBox(height: 10),
              TextField(controller: noteC,
                  decoration: InputDecoration(labelText: context.t('note'),
                      prefixIcon: const Icon(Icons.note_outlined))),
              const SizedBox(height: 14),

              // Smart Agreement toggle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: hasAgreement ? 0.12 : 0.04),
                    Theme.of(context).colorScheme.primary.withValues(alpha: hasAgreement ? 0.06 : 0.02),
                  ]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: hasAgreement ? 0.3 : 0.1)),
                ),
                child: Column(children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Row(children: [
                      Icon(Icons.gavel_rounded, size: 20,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(context.t('enable_agreement'),
                          style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600)),
                    ]),
                    subtitle: Text(context.t('agreement_enabled'),
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    value: hasAgreement,
                    onChanged: (v) => setModalState(() => hasAgreement = v),
                  ),
                  if (hasAgreement) ...[
                    const Divider(),
                    // Payment method
                    DropdownButtonFormField<String>(
                      initialValue: paymentMethod,
                      items: paymentMethods.map((m) =>
                          DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (v) => setModalState(() => paymentMethod = v),
                      decoration: InputDecoration(labelText: context.t('payment_method'),
                          prefixIcon: const Icon(Icons.account_balance_wallet_outlined)),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: penaltyC,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: context.t('penalty_rate'),
                            prefixIcon: const Icon(Icons.percent),
                            helperText: 'e.g. 2 = 2% daily penalty')),
                    const SizedBox(height: 10),
                    TextField(controller: termsC, maxLines: 3,
                        decoration: InputDecoration(labelText: context.t('agreement_terms'),
                            hintText: context.t('agreement_terms_hint'),
                            prefixIcon: const Padding(
                                padding: EdgeInsets.only(bottom: 40),
                                child: Icon(Icons.description_outlined)),
                            alignLabelWithHint: true)),
                  ],
                ]),
              ),
              const SizedBox(height: 14),

              // Save button
              SizedBox(width: double.infinity, child: StatefulBuilder(
                builder: (context, setBtn) => ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    final person = personC.text.trim();
                    final amount = double.tryParse(amountC.text.trim());
                    if (person.isEmpty || amount == null || amount <= 0) {
                      ScaffoldMessenger.of(sheetCtx).showSnackBar(
                          SnackBar(content: Text(context.t('enter_valid_person_amount'))));
                      return;
                    }
                    setBtn(() => isSaving = true);
                    final clampedPaid = existing == null ? 0.0
                        : existing.paidAmount.clamp(0.0, amount);
                    final isSettled = clampedPaid >= amount;
                    final penalty = double.tryParse(penaltyC.text.trim()) ?? 0;

                    final debt = (existing ?? DebtModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      type: type, personName: person, amount: amount,
                    )).copyWith(
                      type: type, personName: person, amount: amount,
                      dueDate: dueDate,
                      note: noteC.text.trim().isEmpty ? null : noteC.text.trim(),
                      createdAt: existing?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                      paidAmount: clampedPaid, isSettled: isSettled,
                      phoneNumber: phoneC.text.trim().isEmpty ? null : phoneC.text.trim(),
                      hasAgreement: hasAgreement,
                      penaltyRate: penalty,
                      agreementTerms: termsC.text.trim().isEmpty ? null : termsC.text.trim(),
                      paymentMethod: paymentMethod,
                      agreementStatus: isSettled ? AgreementStatus.completed
                          : hasAgreement ? AgreementStatus.accepted : AgreementStatus.pending,
                    );

                    if (existing == null) {
                      await ref.read(debtsProvider.notifier).addDebt(debt);
                      // Send SMS notification to the person after creating agreement
                      if (debt.phoneNumber?.isNotEmpty == true) {
                        await _sendAgreementSms(debt, currency);
                      }
                    } else {
                      await ref.read(debtsProvider.notifier).updateDebt(debt);
                      await _cancelDebtReminder(existing);
                    }
                    await _scheduleDebtReminder(debt);
                    if (!sheetCtx.mounted) return;
                    Navigator.pop(sheetCtx);
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
                      content: Text(existing == null
                          ? context.t('debt_added_success')
                          : context.t('debt_updated_success')),
                    ));
                  },
                  child: Text(existing == null ? context.t('create_agreement') : context.t('update')),
                ),
              )),
            ]),
          );
        });
      },
    );
  }

  Widget _buildDatePicker(BuildContext context, DateTime? dueDate, ValueChanged<DateTime?> onChanged) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.t('due_date'),
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(dueDate == null ? context.t('not_set')
              : DateFormat('dd MMM yyyy').format(dueDate),
              style: AppTextStyles.body1),
        ])),
        IconButton(
          icon: const Icon(Icons.calendar_today_outlined),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: dueDate ?? DateTime.now(),
              firstDate: DateTime(2020), lastDate: DateTime(2101),
              useRootNavigator: true,
            );
            if (picked != null) onChanged(picked);
          },
        ),
        if (dueDate != null)
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: context.t('clear_date'),
            onPressed: () => onChanged(null),
          ),
      ]),
    );
  }

  // ── MANUAL PENALTY ─────────────────────────────────────

  Future<void> _openPenaltyDialog(DebtModel debt, String currency) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('add_penalty')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(context.t('add_penalty_hint'),
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: context.t('penalty_amount'),
              prefixText: '$currency ',
              prefixIcon: const Icon(Icons.warning_amber_rounded),
            ),
          ),
          const SizedBox(height: 8),
          if (debt.penaltyAmount > 0)
            Text('${context.t('current_penalty')}: $currency${debt.penaltyAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, color: AppColors.error)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('cancel'))),
          ElevatedButton(
            onPressed: () async {
              final add = double.tryParse(controller.text.trim()) ?? 0;
              if (add <= 0) return;
              final penaltyMsg = '${context.t('penalty_added')}: $currency${add.toStringAsFixed(0)}';
              final updated = debt.copyWith(
                penaltyAmount: debt.penaltyAmount + add,
                updatedAt: DateTime.now(),
              );
              await ref.read(debtsProvider.notifier).updateDebt(updated);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(penaltyMsg)));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(context.t('add_penalty')),
          ),
        ],
      ),
    );
  }

  // ── SMS AFTER AGREEMENT ────────────────────────────────

  Future<void> _sendAgreementSms(DebtModel debt, String currency) async {
    if (debt.phoneNumber == null || debt.phoneNumber!.isEmpty) return;
    final isLent = debt.type == DebtType.lent;
    final msg = StringBuffer()
      ..write('CashTrack Agreement: ')
      ..write(isLent ? 'You owe' : 'I owe you')
      ..write(' $currency${debt.amount.toStringAsFixed(0)}');
    if (debt.dueDate != null) {
      msg.write('. Due: ${DateFormat('dd MMM yyyy').format(debt.dueDate!)}');
    }
    if (debt.penaltyRate > 0) {
      msg.write('. Penalty: ${debt.penaltyRate}% daily after deadline');
    }
    msg.write('.');

    final smsUri = Uri.parse('sms:${debt.phoneNumber}?body=${Uri.encodeComponent(msg.toString())}');
    try { await launchUrl(smsUri); } catch (_) {}
  }

  // ── HELPERS ────────────────────────────────────────────

  Future<void> _scheduleDebtReminder(DebtModel debt) async {
    if (kIsWeb || debt.dueDate == null || debt.isSettled) return;
    await NotificationService().scheduleDebtReminder(
      debtId: debt.id, personName: debt.personName,
      dueDate: debt.dueDate!, amount: debt.amount - debt.paidAmount,
      isBorrowed: debt.type == DebtType.borrowed,
    );
  }

  Future<void> _cancelDebtReminder(DebtModel debt) async {
    if (kIsWeb) return;
    await NotificationService().cancelDebtReminder(debt.id);
  }

  String _currencyFromSettings(Map<String, dynamic> settings) {
    final value = (settings['currency'] as String?)?.trim();
    if (value == null || value.isEmpty || value == '?' || value == 'à§³') return _defaultCurrency;
    return value;
  }
}
