// lib/presentation/tools/shopping_planner_screen.dart
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
import '../providers/app_providers.dart';

class ShoppingPlannerScreen extends ConsumerStatefulWidget {
  const ShoppingPlannerScreen({super.key});

  @override
  ConsumerState<ShoppingPlannerScreen> createState() => _ShoppingPlannerScreenState();
}

class _ShoppingPlannerScreenState extends ConsumerState<ShoppingPlannerScreen>
    with TickerProviderStateMixin {
  static const _boxName = 'settingsBox';
  static const _storageKey = 'shopping_planner_lists_v1';

  List<_ShoppingList> _lists = [];
  int _selectedListIndex = 0;
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

    _loadLists();
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

  Future<void> _loadLists() async {
    final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
    final raw = box.get(_storageKey);

    List<_ShoppingList> loaded = [];
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List;
        loaded = decoded.map((e) => _ShoppingList.fromMap(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    if (loaded.isEmpty) {
      // Default sample lists for Bangladeshi users
      loaded = [
        _ShoppingList(
          id: const Uuid().v4(),
          title: 'Monthly Bazaar',
          createdAt: DateTime.now(),
          items: [
            _ShoppingItem(id: '1', name: 'Miniket Rice', quantity: '25 KG', estimatedPrice: 1850, isCompleted: false),
            _ShoppingItem(id: '2', name: 'Soybean Oil', quantity: '5 Liter', estimatedPrice: 920, isCompleted: false),
            _ShoppingItem(id: '3', name: 'Lentils', quantity: '2 KG', estimatedPrice: 280, isCompleted: false),
            _ShoppingItem(id: '4', name: 'Onions', quantity: '3 KG', estimatedPrice: 240, isCompleted: false),
            _ShoppingItem(id: '5', name: 'Eggs', quantity: '2 Dozen', estimatedPrice: 310, isCompleted: false),
          ],
        ),
      ];
      await box.put(_storageKey, jsonEncode(loaded.map((e) => e.toMap()).toList()));
    }

    if (mounted) {
      setState(() {
        _lists = loaded;
        _loading = false;
      });
    }
  }

  Future<void> _saveLists() async {
    final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
    await box.put(_storageKey, jsonEncode(_lists.map((e) => e.toMap()).toList()));
  }

  void _createNewListDialog() {
    final titleCtrl = TextEditingController(text: context.t('shopping_planner'));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.t('new_list'), style: const TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: titleCtrl,
          decoration: InputDecoration(
            labelText: context.t('item_name'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('cancel'))),
          ElevatedButton(
            onPressed: () {
              final name = titleCtrl.text.trim();
              if (name.isNotEmpty) {
                final newList = _ShoppingList(
                  id: const Uuid().v4(),
                  title: name,
                  createdAt: DateTime.now(),
                  items: [],
                );
                setState(() {
                  _lists.add(newList);
                  _selectedListIndex = _lists.length - 1;
                });
                _saveLists();
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDefault,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(context.t('save')),
          ),
        ],
      ),
    );
  }

  void _editOrDeleteListMenu(_ShoppingList list, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(context.t('rename_list')),
                onTap: () {
                  Navigator.pop(ctx);
                  _renameListDialog(list);
                },
              ),
              if (_lists.length > 1)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: Text(context.t('delete_list'), style: const TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteList(index);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _renameListDialog(_ShoppingList list) {
    final titleCtrl = TextEditingController(text: list.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.t('rename_list'), style: const TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: titleCtrl,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('cancel'))),
          ElevatedButton(
            onPressed: () {
              final name = titleCtrl.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  list.title = name;
                });
                _saveLists();
              }
              Navigator.pop(ctx);
            },
            child: Text(context.t('save')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteList(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.t('delete_list')),
        content: Text(context.t('confirm_delete_list')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _lists.removeAt(index);
                if (_selectedListIndex >= _lists.length) {
                  _selectedListIndex = (_lists.length - 1).clamp(0, _lists.length);
                }
              });
              _saveLists();
              Navigator.pop(ctx);
            },
            child: Text(context.t('delete')),
          ),
        ],
      ),
    );
  }

  void _addItemDialog() {
    if (_lists.isEmpty) return;
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final commonItems = isBn 
        ? ['চাল', 'ডাল', 'তেল', 'পেঁয়াজ', 'আলু', 'ডিম', 'দুধ', 'মাছ', 'মুরগি', 'মসলা', 'সবজি', 'ফল']
        : ['Rice', 'Lentils', 'Oil', 'Onions', 'Potatoes', 'Eggs', 'Milk', 'Fish', 'Chicken', 'Spices', 'Vegetables', 'Fruits'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(context.t('add_item'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick chip presets
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: commonItems.map((item) {
                    return ActionChip(
                      label: Text(item, style: const TextStyle(fontSize: 11)),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      onPressed: () {
                        setDialogState(() {
                          nameCtrl.text = item;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: context.t('item_name'),
                    hintText: isBn ? 'যেমন: মিনিকেট চাল' : 'e.g. Miniket Rice',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        decoration: InputDecoration(
                          labelText: context.t('quantity'),
                          hintText: 'e.g. 2 KG',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: context.t('estimated_budget'),
                          hintText: '500',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('cancel'))),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  final price = double.tryParse(priceCtrl.text.replaceAll(',', '')) ?? 0.0;
                  final item = _ShoppingItem(
                    id: const Uuid().v4(),
                    name: name,
                    quantity: qtyCtrl.text.trim(),
                    estimatedPrice: price,
                    isCompleted: false,
                  );
                  setState(() {
                    _lists[_selectedListIndex].items.add(item);
                  });
                  _saveLists();
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDefault,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(context.t('save')),
            ),
          ],
        ),
      ),
    );
  }

  void _editItemDialog(_ShoppingItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final qtyCtrl = TextEditingController(text: item.quantity);
    final estPriceCtrl = TextEditingController(text: item.estimatedPrice > 0 ? item.estimatedPrice.round().toString() : '');
    final actPriceCtrl = TextEditingController(text: (item.actualPrice != null && item.actualPrice! > 0) ? item.actualPrice!.round().toString() : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(context.t('edit_item'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: context.t('item_name'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: qtyCtrl,
                decoration: InputDecoration(
                  labelText: context.t('quantity'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: estPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.t('estimated_budget'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: actPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.t('actual_price'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('cancel'))),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                final est = double.tryParse(estPriceCtrl.text.replaceAll(',', '')) ?? 0.0;
                final act = double.tryParse(actPriceCtrl.text.replaceAll(',', ''));
                setState(() {
                  item.name = name;
                  item.quantity = qtyCtrl.text.trim();
                  item.estimatedPrice = est;
                  item.actualPrice = act;
                });
                _saveLists();
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDefault,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(context.t('save')),
          ),
        ],
      ),
    );
  }

  void _convertListToExpense(_ShoppingList list) {
    if (list.items.isEmpty) return;

    double totalSpent = 0;
    final itemSummaries = <String>[];

    for (final item in list.items) {
      final itemPrice = (item.actualPrice != null && item.actualPrice! > 0)
          ? item.actualPrice!
          : item.estimatedPrice;
      totalSpent += itemPrice;
      itemSummaries.add('${item.name}${item.quantity.isNotEmpty ? " (${item.quantity})" : ""}: ৳${itemPrice.round()}');
    }

    final dummyTx = TransactionModel(
      id: '',
      amount: (totalSpent * 100).round(),
      type: TransactionType.expense,
      categoryId: 'cat_grocery',
      accountId: 'acc_cash',
      date: DateTime.now(),
      note: '${list.title}\n${itemSummaries.join(", ")}',
    );

    context.push('/add-transaction', extra: dummyTx);
  }

  String _fmt(double v) {
    return NumberFormat('#,##,###').format(v.round());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final settings = ref.watch(settingsProvider);
    final currency = (settings['currency'] as String?) ?? '৳';

    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentList = (_lists.isNotEmpty && _selectedListIndex < _lists.length)
        ? _lists[_selectedListIndex]
        : null;

    double totalEst = 0;
    double totalActual = 0;
    int completedCount = 0;

    if (currentList != null) {
      for (final i in currentList.items) {
        totalEst += i.estimatedPrice;
        final act = (i.actualPrice != null && i.actualPrice! > 0) ? i.actualPrice! : (i.isCompleted ? i.estimatedPrice : 0);
        totalActual += act;
        if (i.isCompleted) completedCount++;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.t('shopping_planner')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItemDialog,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.t('add_item'), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Lists Horizontal Selector ────────────────────────────
            SliverToBoxAdapter(
              child: _anim(index: 1, child: _buildListsSelector(context, isDark, primary)),
            ),

            // ── Summary Card ─────────────────────────────────────────
            if (currentList != null)
              SliverToBoxAdapter(
                child: _anim(
                  index: 2,
                  child: _buildSummaryCard(context, isDark, primary, currency, currentList, totalEst, totalActual, completedCount),
                ),
              ),

            // ── Items List ───────────────────────────────────────────
            if (currentList != null && currentList.items.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildItemTile(ctx, isDark, primary, currency, currentList.items[i]),
                    childCount: currentList.items.length,
                  ),
                ),
              )
            else if (currentList != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 10),
                      Text(context.t('no_items_in_list'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: _addItemDialog,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(context.t('add_first_item')),
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

  Widget _buildListsSelector(BuildContext context, bool isDark, Color primary) {
    return Container(
      height: 42,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _lists.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          if (i == _lists.length) {
            return ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 14),
              label: Text(context.t('new_list'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              onPressed: _createNewListDialog,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            );
          }
          final list = _lists[i];
          final isSelected = _selectedListIndex == i;
          return GestureDetector(
            onLongPress: () => _editOrDeleteListMenu(list, i),
            child: ChoiceChip(
              avatar: isSelected && _lists.length > 1
                  ? GestureDetector(
                      onTap: () => _editOrDeleteListMenu(list, i),
                      child: const Icon(Icons.more_horiz_rounded, size: 16, color: Colors.white),
                    )
                  : null,
              label: Text(
                list.title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              selected: isSelected,
              selectedColor: primary,
              backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (val) {
                if (val) setState(() => _selectedListIndex = i);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    bool isDark,
    Color primary,
    String currency,
    _ShoppingList list,
    double totalEst,
    double totalActual,
    int completedCount,
  ) {
    final progress = list.items.isNotEmpty ? (completedCount / list.items.length) : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF0284C7), const Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.3 : 0.2),
            blurRadius: 16,
            offset: const Offset(0, 5),
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
                context.t('budget_expense_summary'),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.8)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.t('items_completed_count', params: {'completed': completedCount.toString(), 'total': list.items.length.toString()}),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t('estimated_budget'), style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7))),
                  Text('$currency${_fmt(totalEst)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                ],
              ),
              Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t('shopping_done'), style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7))),
                  Text('$currency${_fmt(totalActual)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF67E8F9))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _convertListToExpense(list),
              icon: const Icon(Icons.receipt_long_rounded, size: 16),
              label: Text(context.t('add_total_expense_1click')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0369A1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(
    BuildContext context,
    bool isDark,
    Color primary,
    String currency,
    _ShoppingItem item,
  ) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() {
          _lists[_selectedListIndex].items.removeWhere((i) => i.id == item.id);
        });
        _saveLists();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isCompleted
                ? AppColors.success.withValues(alpha: 0.3)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _editItemDialog(item),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: item.isCompleted,
                    activeColor: AppColors.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    onChanged: (val) {
                      setState(() {
                        item.isCompleted = val ?? false;
                      });
                      _saveLists();
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                            color: item.isCompleted
                                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (item.quantity.isNotEmpty)
                          Text(
                            item.quantity,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$currency${_fmt(item.estimatedPrice)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: item.isCompleted ? AppColors.success : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (item.actualPrice != null && item.actualPrice! > 0)
                        Text(
                          'Act: $currency${_fmt(item.actualPrice!)}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.edit_outlined, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShoppingList {
  final String id;
  String title;
  final DateTime createdAt;
  List<_ShoppingItem> items;

  _ShoppingList({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.items,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'items': items.map((i) => i.toMap()).toList(),
      };

  factory _ShoppingList.fromMap(Map<String, dynamic> map) => _ShoppingList(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
        items: (map['items'] as List? ?? [])
            .map((i) => _ShoppingItem.fromMap(Map<String, dynamic>.from(i)))
            .toList(),
      );
}

class _ShoppingItem {
  final String id;
  String name;
  String quantity;
  double estimatedPrice;
  double? actualPrice;
  bool isCompleted;

  _ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.estimatedPrice,
    this.actualPrice,
    required this.isCompleted,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'estimatedPrice': estimatedPrice,
        'actualPrice': actualPrice,
        'isCompleted': isCompleted,
      };

  factory _ShoppingItem.fromMap(Map<String, dynamic> map) => _ShoppingItem(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        quantity: map['quantity'] ?? '',
        estimatedPrice: (map['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
        actualPrice: (map['actualPrice'] as num?)?.toDouble(),
        isCompleted: map['isCompleted'] ?? false,
      );
}
