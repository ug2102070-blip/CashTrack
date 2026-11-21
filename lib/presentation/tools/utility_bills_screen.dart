// lib/presentation/tools/utility_bills_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/transaction_model.dart';

enum BillType { electricity, gas, water, internet, rent, creditCard, others }

class UtilityBillsScreen extends ConsumerStatefulWidget {
  const UtilityBillsScreen({super.key});

  @override
  ConsumerState<UtilityBillsScreen> createState() => _UtilityBillsScreenState();
}

class _UtilityBillsScreenState extends ConsumerState<UtilityBillsScreen>
    with TickerProviderStateMixin {
  static const _boxName = 'settingsBox';
  static const _storageKey = 'utility_bills_list_v1';

  List<_BillItem> _bills = [];
  bool _loading = true;

  late AnimationController _entryCtrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  static const List<int> _delays = [0, 80, 160, 240];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();

    _fadeAnims = _delays.map((ms) {
      final s = (ms / 850).clamp(0.0, 1.0);
      final e = ((ms + 300) / 850).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _entryCtrl, curve: Interval(s, e, curve: Curves.easeOut));
    }).toList();

    _slideAnims = _delays.map((ms) {
      final s = (ms / 850).clamp(0.0, 1.0);
      final e = ((ms + 300) / 850).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
          .animate(CurvedAnimation(parent: _entryCtrl, curve: Interval(s, e, curve: Curves.easeOutCubic)));
    }).toList();

    _loadBills();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Widget _anim({required int index, required Widget child}) {
    final i = index.clamp(0, _fadeAnims.length - 1);
    return FadeTransition(
      opacity: _fadeAnims[i],
      child: SlideTransition(position: _slideAnims[i], child: child),
    );
  }

  String get _currentMonthKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, "0")}';
  }

  Future<void> _loadBills() async {
    final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
    final raw = box.get(_storageKey);

    List<_BillItem> loaded = [];
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List;
        loaded = decoded.map((e) => _BillItem.fromMap(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    if (loaded.isEmpty) {
      // Default common Bangladesh utilities
      loaded = [
        _BillItem(
          id: const Uuid().v4(),
          type: BillType.electricity,
          title: 'DESCO Electricity Bill',
          meterNo: '10293847',
          amount: 2200,
          dueDay: 15,
          lastPaidMonth: '',
        ),
        _BillItem(
          id: const Uuid().v4(),
          type: BillType.internet,
          title: 'WiFi Internet Bill',
          meterNo: 'L3-84729',
          amount: 1000,
          dueDay: 10,
          lastPaidMonth: '',
        ),
        _BillItem(
          id: const Uuid().v4(),
          type: BillType.gas,
          title: 'Titas Gas Bill',
          meterNo: 'T-9382',
          amount: 1080,
          dueDay: 20,
          lastPaidMonth: '',
        ),
      ];
      await box.put(_storageKey, jsonEncode(loaded.map((e) => e.toMap()).toList()));
    }

    if (mounted) {
      setState(() {
        _bills = loaded;
        _loading = false;
      });
    }
  }

  Future<void> _saveBills() async {
    final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
    await box.put(_storageKey, jsonEncode(_bills.map((e) => e.toMap()).toList()));
  }

  void _addOrEditBillDialog([_BillItem? existing]) {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final meterCtrl = TextEditingController(text: existing?.meterNo ?? '');
    final amountCtrl = TextEditingController(text: existing != null ? existing.amount.round().toString() : '');
    int dueDay = existing?.dueDay ?? 10;
    BillType selectedType = existing?.type ?? BillType.electricity;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(isEdit ? 'Edit Bill' : 'Add New Utility Bill', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type selector
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: BillType.values.map((t) {
                    final isSel = selectedType == t;
                    return ChoiceChip(
                      label: Text(_typeLabel(t), style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
                      selected: isSel,
                      selectedColor: AppColors.primaryDefault,
                      onSelected: (v) {
                        if (v) setDialogState(() => selectedType = t);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Bill Name / Provider',
                    hintText: 'e.g. DESCO, WASA, Rent',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: meterCtrl,
                  decoration: InputDecoration(
                    labelText: 'Meter / Customer No (Optional)',
                    hintText: 'Consumer / Account ID',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Bill Amount (৳)',
                          hintText: 'e.g. 1500',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: dueDay,
                        decoration: InputDecoration(
                          labelText: 'Due Date of Each Month',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        items: List.generate(31, (i) => i + 1).map((d) {
                          return DropdownMenuItem<int>(
                            value: d,
                            child: Text('$d', style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => dueDay = val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                final amt = double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0.0;
                if (title.isNotEmpty) {
                  setState(() {
                    if (isEdit) {
                      existing.title = title;
                      existing.meterNo = meterCtrl.text.trim();
                      existing.amount = amt;
                      existing.dueDay = dueDay;
                      existing.type = selectedType;
                    } else {
                      _bills.add(_BillItem(
                        id: const Uuid().v4(),
                        title: title,
                        meterNo: meterCtrl.text.trim(),
                        amount: amt,
                        dueDay: dueDay,
                        type: selectedType,
                        lastPaidMonth: '',
                      ));
                    }
                  });
                  _saveBills();
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDefault,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _payAndRecordExpense(_BillItem bill) {
    final dummyTx = TransactionModel(
      id: '',
      amount: (bill.amount * 100).round(),
      type: TransactionType.expense,
      categoryId: 'cat_bills',
      accountId: 'acc_cash',
      date: DateTime.now(),
      note: '${bill.title} পরিশোধ${bill.meterNo.isNotEmpty ? " (নম্বর: ${bill.meterNo})" : ""}',
    );

    // Update bill to paid
    setState(() {
      bill.lastPaidMonth = _currentMonthKey;
    });
    _saveBills();

    context.push('/add-transaction', extra: dummyTx);
  }

  String _typeLabel(BillType type) {
    switch (type) {
      case BillType.electricity:
        return 'Electricity';
      case BillType.gas:
        return 'Gas';
      case BillType.water:
        return 'Water (WASA)';
      case BillType.internet:
        return 'Internet / WiFi';
      case BillType.rent:
        return 'House Rent';
      case BillType.creditCard:
        return 'Credit Card';
      case BillType.others:
        return 'Other';
    }
  }

  IconData _typeIcon(BillType type) {
    switch (type) {
      case BillType.electricity:
        return Icons.bolt_rounded;
      case BillType.gas:
        return Icons.local_fire_department_rounded;
      case BillType.water:
        return Icons.water_drop_rounded;
      case BillType.internet:
        return Icons.wifi_rounded;
      case BillType.rent:
        return Icons.home_rounded;
      case BillType.creditCard:
        return Icons.credit_card_rounded;
      case BillType.others:
        return Icons.receipt_rounded;
    }
  }

  Color _typeColor(BillType type) {
    switch (type) {
      case BillType.electricity:
        return const Color(0xFFF59E0B);
      case BillType.gas:
        return const Color(0xFFEF4444);
      case BillType.water:
        return const Color(0xFF0EA5E9);
      case BillType.internet:
        return const Color(0xFF6366F1);
      case BillType.rent:
        return const Color(0xFF8B5CF6);
      case BillType.creditCard:
        return const Color(0xFFEC4899);
      case BillType.others:
        return const Color(0xFF10B981);
    }
  }

  String _fmt(double v) {
    return NumberFormat('#,##,###').format(v.round());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    double totalMonthlyBills = 0;
    double totalPaidSoFar = 0;
    int dueBillsCount = 0;

    for (final b in _bills) {
      totalMonthlyBills += b.amount;
      final isPaid = b.lastPaidMonth == _currentMonthKey;
      if (isPaid) {
        totalPaidSoFar += b.amount;
      } else {
        dueBillsCount++;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.t('utility_bills')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditBillDialog(),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.t('add_new_bill'), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ── Hero Summary Card ─────────────────────────────────────
            SliverToBoxAdapter(
              child: _anim(
                index: 1,
                child: _buildHeroCard(context, isDark, primary, totalMonthlyBills, totalPaidSoFar, dueBillsCount),
              ),
            ),

            // ── Bills List ───────────────────────────────────────────
            if (_bills.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildBillTile(ctx, isDark, _bills[i]),
                    childCount: _bills.length,
                  ),
                ),
              )
            else
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 10),
                      Text(context.t('no_utility_bills_added'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () => _addOrEditBillDialog(),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(context.t('add_first_bill')),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }



  Widget _buildHeroCard(
    BuildContext context,
    bool isDark,
    Color primary,
    double totalBills,
    double totalPaid,
    int dueBillsCount,
  ) {
    final progress = totalBills > 0 ? (totalPaid / totalBills).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF4C1D95), const Color(0xFF2E1065)]
              : [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.35 : 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.t('current_month_utility_bill'),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.8)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: dueBillsCount > 0 ? const Color(0xFFF59E0B).withValues(alpha: 0.3) : Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dueBillsCount > 0 ? const Color(0xFFFDE047) : Colors.transparent),
                ),
                child: Text(
                  dueBillsCount > 0 ? context.t('due_bills_count', params: {'count': dueBillsCount.toString()}) : context.t('all_bills_paid'),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '৳${_fmt(totalBills)}',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA78BFA)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.t('paid_amount', params: {'amount': _fmt(totalPaid)}), style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
              Text(context.t('due_amount', params: {'amount': _fmt(totalBills - totalPaid)}), style: const TextStyle(fontSize: 11, color: Color(0xFFFDE047), fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillTile(
    BuildContext context,
    bool isDark,
    _BillItem bill,
  ) {
    final isPaid = bill.lastPaidMonth == _currentMonthKey;
    final color = _typeColor(bill.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPaid
              ? AppColors.success.withValues(alpha: 0.25)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_typeIcon(bill.type), color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  context.t('every_month_date', params: {'date': bill.dueDay.toString()}) + (bill.meterNo.isNotEmpty ? ' · ${bill.meterNo}' : ''),
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '৳${_fmt(bill.amount)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isPaid)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 12),
                      const SizedBox(width: 4),
                      Text(context.t('paid'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success)),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () => _payAndRecordExpense(bill),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDefault,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(context.t('pay'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              const SizedBox(height: 4),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                onSelected: (val) {
                  if (val == 'edit') {
                    _addOrEditBillDialog(bill);
                  } else if (val == 'delete') {
                    setState(() => _bills.removeWhere((b) => b.id == bill.id));
                    _saveBills();
                  } else if (val == 'toggle_paid') {
                    setState(() {
                      bill.lastPaidMonth = isPaid ? '' : _currentMonthKey;
                    });
                    _saveBills();
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(value: 'toggle_paid', child: Text(isPaid ? context.t('mark_as_unpaid') : context.t('mark_as_paid'))),
                  PopupMenuItem(value: 'edit', child: Text(context.t('edit'))),
                  PopupMenuItem(value: 'delete', child: Text(context.t('delete'), style: const TextStyle(color: AppColors.error))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillItem {
  final String id;
  String title;
  String meterNo;
  double amount;
  int dueDay;
  BillType type;
  String lastPaidMonth;

  _BillItem({
    required this.id,
    required this.title,
    required this.meterNo,
    required this.amount,
    required this.dueDay,
    required this.type,
    required this.lastPaidMonth,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'meterNo': meterNo,
        'amount': amount,
        'dueDay': dueDay,
        'type': type.index,
        'lastPaidMonth': lastPaidMonth,
      };

  factory _BillItem.fromMap(Map<String, dynamic> map) => _BillItem(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        meterNo: map['meterNo'] ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        dueDay: map['dueDay'] ?? 10,
        type: BillType.values[(map['type'] as int? ?? 0).clamp(0, BillType.values.length - 1)],
        lastPaidMonth: map['lastPaidMonth'] ?? '',
      );
}
