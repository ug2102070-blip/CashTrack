// lib/presentation/assets/assets_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/l10n/app_l10n.dart';
import '../../data/models/asset_model.dart';
import '../providers/app_providers.dart';

class AssetsScreen extends ConsumerWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(assetsProvider);
    final settings = ref.watch(settingsProvider);
    final currency = (settings['currency'] as String?) ?? '\u09F3';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalPurchase = assets.fold<double>(0, (s, a) => s + a.purchasePrice);
    final totalCurrent = assets.fold<double>(0, (s, a) => s + a.currentValue);
    final appreciation = totalCurrent - totalPurchase;
    final appPct = totalPurchase > 0 ? (appreciation / totalPurchase * 100) : 0.0;
    final isPos = appreciation >= 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header(context, ref, isDark)),
            SliverToBoxAdapter(child: _hero(context, currency, totalPurchase, totalCurrent, appreciation, appPct, isPos)),
            if (assets.isEmpty)
              SliverFillRemaining(child: _empty(context, ref))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _card(context, ref, assets[i], currency, isDark),
                    childCount: assets.length,
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
          icon: Container(width: 38, height: 38,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.arrow_back_rounded, size: 18,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ),
        const SizedBox(width: 4),
        Text(context.t('assets_title'), style: AppTextStyles.h2.copyWith(
            fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.3,
            color: Theme.of(context).colorScheme.onSurface)),
      ]),
    );
  }

  Widget _hero(BuildContext context, String cur, double purchase, double current, double app, double pct, bool pos) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF047857), Color(0xFF065F46)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
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
                const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 13),
                const SizedBox(width: 5),
                Text(context.t('asset_tracker'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
            const Spacer(),
            if (purchase > 0) Container(
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
            Expanded(child: _hStat(context.t('purchase_value'), '$cur${_f(purchase)}')),
            Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.15)),
            Expanded(child: _hStat(context.t('current_value'), '$cur${_f(current)}')),
            Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.15)),
            Expanded(child: _hStat(context.t('appreciation'), '${pos ? '+' : ''}$cur${_f(app.abs())}')),
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

  Widget _card(BuildContext context, WidgetRef ref, AssetModel asset, String cur, bool isDark) {
    final app = asset.currentValue - asset.purchasePrice;
    final pos = app >= 0;
    final hasWarranty = asset.warrantyExpiry != null && asset.warrantyExpiry!.isAfter(DateTime.now());
    return GestureDetector(
      onTap: () => _showSheet(context, ref, asset),
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
              decoration: BoxDecoration(color: const Color(0xFF059669).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF059669), size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(asset.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
              if (asset.category != null && asset.category!.isNotEmpty)
                Text(asset.category!, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45))),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$cur${_f(asset.currentValue)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
              Text('${pos ? '+' : '-'}$cur${_f(app.abs())}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: pos ? AppColors.success : AppColors.error)),
            ]),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Text('${context.t('purchase_price')}: $cur${_f(asset.purchasePrice)}',
                style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
            const Spacer(),
            if (hasWarranty) Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(context.t('warranty_active'), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.success)),
            ),
            const SizedBox(width: 6),
            Text(DateFormat('dd MMM yy').format(asset.purchaseDate),
                style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35))),
          ]),
        ]),
      ),
    );
  }

  Widget _empty(BuildContext context, WidgetRef ref) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 72, height: 72,
      decoration: BoxDecoration(color: const Color(0xFF059669).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
      child: const Icon(Icons.inventory_2_rounded, size: 34, color: Color(0xFF059669))),
    const SizedBox(height: 16),
    Text(context.t('no_assets_yet'), style: AppTextStyles.h5.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
    const SizedBox(height: 6),
    Text(context.t('add_first_asset'), style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))),
    const SizedBox(height: 20),
    ElevatedButton.icon(
      onPressed: () => _showSheet(context, ref, null),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(context.t('add_asset')),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  ]));

  void _showSheet(BuildContext context, WidgetRef ref, AssetModel? ex) {
    final isEdit = ex != null;
    final nc = TextEditingController(text: ex?.name ?? '');
    final pc = TextEditingController(text: ex != null ? ex.purchasePrice.toStringAsFixed(0) : '');
    final cc = TextEditingController(text: ex != null ? ex.currentValue.toStringAsFixed(0) : '');
    final catc = TextEditingController(text: ex?.category ?? '');
    final notec = TextEditingController(text: ex?.note ?? '');
    DateTime purchaseDate = ex?.purchaseDate ?? DateTime.now();
    DateTime? warrantyExp = ex?.warrantyExpiry;
    DateTime? insuranceExp = ex?.insuranceExpiry;

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
            Text(isEdit ? context.t('edit_asset') : context.t('add_asset'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(controller: nc, decoration: InputDecoration(labelText: context.t('asset_name'))),
            const SizedBox(height: 10),
            TextField(controller: catc, decoration: InputDecoration(labelText: context.t('asset_category'))),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: pc, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.t('purchase_price')))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: cc, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.t('current_value')))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () async { final d = await showDatePicker(context: ctx, initialDate: purchaseDate, firstDate: DateTime(2000), lastDate: DateTime.now()); if (d != null) ss(() => purchaseDate = d); },
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(DateFormat('dd/MM/yy').format(purchaseDate), style: const TextStyle(fontSize: 12)),
              )),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(
                onPressed: () async { final d = await showDatePicker(context: ctx, initialDate: warrantyExp ?? DateTime.now().add(const Duration(days: 365)), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d != null) ss(() => warrantyExp = d); },
                icon: const Icon(Icons.verified_user_rounded, size: 16),
                label: Text(warrantyExp != null ? DateFormat('dd/MM/yy').format(warrantyExp!) : context.t('warranty_expiry'), style: const TextStyle(fontSize: 11)),
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
                  final pp = double.tryParse(pc.text.trim()) ?? 0;
                  final cv = double.tryParse(cc.text.trim()) ?? 0;
                  if (nc.text.trim().isEmpty || pp <= 0) return;
                  final now = DateTime.now();
                  final m = AssetModel(id: ex?.id ?? const Uuid().v4(), name: nc.text.trim(),
                    purchasePrice: pp, currentValue: cv > 0 ? cv : pp, purchaseDate: purchaseDate,
                    warrantyExpiry: warrantyExp, insuranceExpiry: insuranceExp,
                    category: catc.text.trim().isEmpty ? null : catc.text.trim(),
                    note: notec.text.trim().isEmpty ? null : notec.text.trim(),
                    createdAt: ex?.createdAt ?? now, updatedAt: now);
                  if (isEdit) { ref.read(assetsProvider.notifier).updateAsset(m); }
                  else { ref.read(assetsProvider.notifier).addAsset(m); }
                  Navigator.pop(ctx);
                },
                child: Text(isEdit ? context.t('update') : context.t('add_asset')),
              )),
            ]),
          ])),
        );
      }),
    );
  }

  void _del(BuildContext context, WidgetRef ref, AssetModel asset) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(context.t('delete_asset')),
      content: Text(context.t('delete_asset_confirm')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('cancel'))),
        TextButton(onPressed: () { ref.read(assetsProvider.notifier).deleteAsset(asset.id); Navigator.pop(ctx); },
          style: TextButton.styleFrom(foregroundColor: AppColors.error), child: Text(context.t('delete'))),
      ],
    ));
  }

  String _f(double v) { if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M'; if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K'; return v.toStringAsFixed(0); }
}
