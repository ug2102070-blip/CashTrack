import 'package:hive/hive.dart';

import '../models/budget_model.dart';
import 'hive_box_recovery.dart';

class BudgetRepository {
  BudgetRepository._internal();
  static final BudgetRepository _instance = BudgetRepository._internal();
  factory BudgetRepository() => _instance;

  static const String _boxName = 'budgets';
  Box<dynamic>? _box;
  bool _initialized = false;

  Box<dynamic>? _currentBoxOrNull() {
    if (_box != null) return _box;
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box(_boxName);
      _initialized = true;
    }
    return _box;
  }

  Future<void> init() async {
    if (_initialized && _box != null) return;
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box(_boxName);
      _initialized = true;
      return;
    }
    _box = await openBoxWithRecovery<dynamic>(_boxName);
    _initialized = true;
  }

  List<BudgetModel> getAllBudgets() {
    return _decodedValues();
  }

  List<BudgetModel> getBudgetsForMonth(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    return _decodedValues()
        .where((budget) =>
            budget.month.year == startOfMonth.year &&
            budget.month.month == startOfMonth.month)
        .toList();
  }

  BudgetModel? getBudgetByCategory(String categoryId, DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    return _decodedValues().firstWhere(
      (budget) =>
          budget.categoryId == categoryId &&
          budget.month.year == startOfMonth.year &&
          budget.month.month == startOfMonth.month,
      orElse: () => throw StateError('Budget not found'),
    );
  }

  Future<void> addBudget(BudgetModel budget) async {
    await init();
    await _box!.put(budget.id, budget.toJson());
  }

  Future<void> updateBudget(BudgetModel budget) async {
    await init();
    await _box!.put(budget.id, budget.toJson());
  }

  Future<void> updateSpent(String budgetId, double newSpent) async {
    await init();
    final budget = _decode(_box!.get(budgetId));
    if (budget != null) {
      await _box!.put(
        budgetId,
        budget.copyWith(spent: newSpent, updatedAt: DateTime.now()).toJson(),
      );
    }
  }

  Future<void> deleteBudget(String id) async {
    await init();
    await _box!.delete(id);
  }

  List<BudgetModel> _decodedValues() {
    final box = _currentBoxOrNull();
    if (box == null) return [];
    return box.values.map(_decode).whereType<BudgetModel>().toList();
  }

  BudgetModel? _decode(dynamic raw) {
    if (raw == null) return null;
    if (raw is BudgetModel) return raw;
    if (raw is Map) {
      return BudgetModel.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }
}
