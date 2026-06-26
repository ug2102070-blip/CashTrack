// lib/presentation/investments/investments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/l10n/app_l10n.dart';
import '../../data/models/investment_model.dart';
import '../providers/app_providers.dart';

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investments = ref.watch(investmentsProvider);
    final settings = ref.watch(settingsProvider);
    final currency = (settings['currency'] as String?) ?? '\u09F3';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalInvested = investments.fold<double>(0, (s, i) => s + i.investedAmount);
    final totalCurrent = investments.fold<double>(0, (s, i) => s + i.currentValue);
    final totalReturns = totalCurrent - totalInvested;
    final returnPct = totalInvested > 0 ? (totalReturns / totalInvested * 100) : 0.0;
    final isPos = totalReturns >= 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header(context, ref, isDark)),
            SliverToBoxAdapter(child: _hero(context, currency, totalInvested, totalCurrent, totalReturns, returnPct, isPos)),
            if (investments.isEmpty)
              SliverFillRemaining(child: _empty(context, ref))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _card(context, ref, investments[i], currency, isDark),
                    childCount: investments.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, WidgetRef ref, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back_rounded, size: 18,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ),
        const SizedBox(width: 4),
        Text(context.t('investments'), style: AppTextStyles.h2.copyWith(
            fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.3,
            color: Theme.of(context).colorScheme.onSurface)),
      ]),
    );
  }

  Widget _hero(BuildContext context, String cur, double inv, double cur2, double ret, double pct, bool pos) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF3730A3)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(children: [
        Positioned(top: -30, right: -20, child: Container(width: 120, height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
        Padding(padding: const EdgeInsets.all(22), child: Column(children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.trending_up_rounded, color: Colors.white, size: 13),
                const SizedBox(width: 5),
                Text(context.t('investment_portfolio'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
            const Spacer(),
            if (inv > 0) Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: (pos ? Colors.green : Colors.red).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${pos ? '+' : ''}${pct.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: _hStat(context.t('total_invested'), '$cur${_f(inv)}')),
            Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.15)),
            Expanded(child: _hStat(context.t('current_value'), '$cur${_f(cur2)}')),
            Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.15)),
            Expanded(child: _hStat(context.t('total_returns'), '${pos ? '+' : ''}$cur${_f(ret.abs())}')),
          ]),
        ])),
      ]),
    );
  }

  Widget _hStat(String l, String v) => Column(children: [
    Text(l, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
    const SizedBox(height: 4),
    Text(v, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.3), textAlign: TextAlign.center),
  ]);

  Widget _card(BuildContext context, WidgetRef ref, InvestmentModel inv, String cur, bool isDark) {
    final ret = inv.currentValue - inv.investedAmount;
    final pct = inv.investedAmount > 0 ? (ret / inv.investedAmount * 100) : 0.0;
    final pos = ret >= 0;
    final tc = _tColor(inv.type);
    return GestureDetector(
      onTap: () => _showSheet(context, ref, inv),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(children: [
          Row(children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(color: tc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
              child: Icon(_tIcon(inv.type), color: tc, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(inv.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
              Text(_tLabel(context, inv.type), style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45))),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$cur${_f(inv.currentValue)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
              Text('${pos ? '+' : ''}${pct.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: pos ? AppColors.success : AppColors.error)),
            ]),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Text('${context.t('invested_amount')}: $cur${_f(inv.investedAmount)}',
                style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
            const Spacer(),
            Text(DateFormat('dd MMM yy').format(inv.startDate),
                style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35))),
          ]),
        ]),
      ),
    );
  }

  Widget _empty(BuildContext context, WidgetRef ref) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 72, height: 72,
      decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
      child: const Icon(Icons.trending_up_rounded, size: 34, color: Color(0xFF6366F1))),
    const SizedBox(height: 16),
    Text(context.t('no_investments_yet'), style: AppTextStyles.h5.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
    const SizedBox(height: 6),
    Text(context.t('add_first_investment'), style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))),
    const SizedBox(height: 20),
    ElevatedButton.icon(
      onPressed: () => _showSheet(context, ref, null),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(context.t('add_investment')),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  ]));

  void _showSheet(BuildContext context, WidgetRef ref, InvestmentModel? ex) {
    final isEdit = ex != null;
    final nc = TextEditingController(text: ex?.name ?? '');
    final ic = TextEditingController(text: ex != null ? ex.investedAmount.toStringAsFixed(0) : '');
    final cc = TextEditingController(text: ex != null ? ex.currentValue.toStringAsFixed(0) : '');
    final rc = TextEditingController(text: ex != null ? ex.expectedReturn.toStringAsFixed(1) : '');
    final notec = TextEditingController(text: ex?.note ?? '');
    InvestmentType selType = ex?.type ?? InvestmentType.fixedDeposit;
    DateTime startDate = ex?.startDate ?? DateTime.now();
    DateTime? matDate = ex?.maturityDate;

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) {
        final theme = Theme.of(ctx);
        final dark = theme.brightness == Brightness.dark;
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: dark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(isEdit ? context.t('edit_investment') : context.t('add_investment'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: InvestmentType.values.map((t) =>
              ChoiceChip(label: Text(_tLabel(context, t)), selected: t == selType, onSelected: (_) => ss(() => selType = t))
            ).toList()),
            const SizedBox(height: 14),
            TextField(controller: nc, decoration: InputDecoration(labelText: context.t('investment_name'))),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: ic, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.t('invested_amount')))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: cc, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.t('current_value')))),
            ]),
            const SizedBox(height: 10),
            TextField(controller: rc, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.t('expected_return'), suffixText: '%')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () async { final d = await showDatePicker(context: ctx, initialDate: startDate, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d != null) ss(() => startDate = d); },
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(DateFormat('dd/MM/yy').format(startDate), style: const TextStyle(fontSize: 12)),
              )),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(
                onPressed: () async { final d = await showDatePicker(context: ctx, initialDate: matDate ?? DateTime.now().add(const Duration(days: 365)), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d != null) ss(() => matDate = d); },
                icon: const Icon(Icons.event_rounded, size: 16),
                label: Text(matDate != null ? DateFormat('dd/MM/yy').format(matDate!) : context.t('maturity_date'), style: const TextStyle(fontSize: 12)),
              )),
            ]),
            const SizedBox(height: 10),
            TextField(controller: notec, decoration: InputDecoration(labelText: context.t('note'))),
            const SizedBox(height: 18),
            Row(children: [
              if (isEdit) ...[
                Expanded(child: OutlinedButton(
                  onPressed: () { Navigator.pop(ctx); _del(context, ref, ex); },
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                  child: Text(context.t('delete')),
                )),
                const SizedBox(width: 10),
              ],
              Expanded(child: ElevatedButton(
                onPressed: () {
                  final inv = double.tryParse(ic.text.trim()) ?? 0;
                  final cur = double.tryParse(cc.text.trim()) ?? 0;
                  if (nc.text.trim().isEmpty || inv <= 0) return;
                  final now = DateTime.now();
                  final m = InvestmentModel(id: ex?.id ?? const Uuid().v4(), name: nc.text.trim(), type: selType,
                    investedAmount: inv, currentValue: cur > 0 ? cur : inv, expectedReturn: double.tryParse(rc.text.trim()) ?? 0,
                    startDate: startDate, maturityDate: matDate, note: notec.text.trim().isEmpty ? null : notec.text.trim(),
                    createdAt: ex?.createdAt ?? now, updatedAt: now);
                  if (isEdit) { ref.read(investmentsProvider.notifier).updateInvestment(m); }
                  else { ref.read(investmentsProvider.notifier).addInvestment(m); }
                  Navigator.pop(ctx);
                },
                child: Text(isEdit ? context.t('update') : context.t('add_investment')),
              )),
            ]),
          ])),
        );
      }),
    );
  }

  void _del(BuildContext context, WidgetRef ref, InvestmentModel inv) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(context.t('delete_investment')),
      content: Text(context.t('delete_investment_confirm')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('cancel'))),
        TextButton(onPressed: () { ref.read(investmentsProvider.notifier).deleteInvestment(inv.id); Navigator.pop(ctx); },
          style: TextButton.styleFrom(foregroundColor: AppColors.error), child: Text(context.t('delete'))),
      ],
    ));
  }

  String _tLabel(BuildContext c, InvestmentType t) {
    switch (t) { case InvestmentType.mutualFund: return c.t('mutual_fund'); case InvestmentType.stock: return c.t('stock');
      case InvestmentType.fixedDeposit: return c.t('fixed_deposit'); case InvestmentType.gold: return c.t('gold_inv');
      case InvestmentType.dps: return c.t('dps'); case InvestmentType.others: return c.t('others_type'); }
  }
  IconData _tIcon(InvestmentType t) {
    switch (t) { case InvestmentType.mutualFund: return Icons.pie_chart_rounded; case InvestmentType.stock: return Icons.candlestick_chart_rounded;
      case InvestmentType.fixedDeposit: return Icons.account_balance_rounded; case InvestmentType.gold: return Icons.diamond_rounded;
      case InvestmentType.dps: return Icons.savings_rounded; case InvestmentType.others: return Icons.category_rounded; }
  }
  Color _tColor(InvestmentType t) {
    switch (t) { case InvestmentType.mutualFund: return const Color(0xFF6366F1); case InvestmentType.stock: return const Color(0xFF3B82F6);
      case InvestmentType.fixedDeposit: return const Color(0xFF10B981); case InvestmentType.gold: return const Color(0xFFF59E0B);
      case InvestmentType.dps: return const Color(0xFF8B5CF6); case InvestmentType.others: return const Color(0xFFEC4899); }
  }
  String _f(double v) { if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M'; if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K'; return v.toStringAsFixed(0); }
}
