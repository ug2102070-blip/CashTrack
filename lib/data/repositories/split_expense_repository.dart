import 'package:hive/hive.dart';

import '../models/split_expense_model.dart';
import 'hive_box_recovery.dart';

class SplitExpenseRepository {
  SplitExpenseRepository._internal();
  static final SplitExpenseRepository _instance =
      SplitExpenseRepository._internal();
  factory SplitExpenseRepository() => _instance;

  static const String _groupBoxName = 'split_groups';
  static const String _expenseBoxName = 'split_expenses';

  Box<dynamic>? _groupBox;
  Box<dynamic>? _expenseBox;
  bool _initialized = false;

  Box<dynamic>? _currentGroupBoxOrNull() {
    if (_groupBox != null) return _groupBox;
    if (Hive.isBoxOpen(_groupBoxName)) {
      _groupBox = Hive.box(_groupBoxName);
    }
    return _groupBox;
  }

  Box<dynamic>? _currentExpenseBoxOrNull() {
    if (_expenseBox != null) return _expenseBox;
    if (Hive.isBoxOpen(_expenseBoxName)) {
      _expenseBox = Hive.box(_expenseBoxName);
    }
    return _expenseBox;
  }

  Future<void> init() async {
    if (_initialized) return;
    if (!Hive.isBoxOpen(_groupBoxName)) {
      _groupBox = await openBoxWithRecovery<dynamic>(_groupBoxName);
    } else {
      _groupBox = Hive.box(_groupBoxName);
    }

    if (!Hive.isBoxOpen(_expenseBoxName)) {
      _expenseBox = await openBoxWithRecovery<dynamic>(_expenseBoxName);
    } else {
      _expenseBox = Hive.box(_expenseBoxName);
    }

    _initialized = true;
  }

  List<SplitGroup> getAllGroups() {
    return _decodedGroupValues();
  }

  SplitGroup? getGroupById(String id) {
    return _decodeGroup(_currentGroupBoxOrNull()?.get(id));
  }

  Future<void> addGroup(SplitGroup group) async {
    await init();
    await _groupBox!.put(group.id, group.toJson());
  }

  Future<void> updateGroup(SplitGroup group) async {
    await init();
    await _groupBox!.put(group.id, group.toJson());
  }

  Future<void> deleteGroup(String id) async {
    await init();
    await _groupBox!.delete(id);
    final expenses = getExpensesByGroup(id);
    for (final expense in expenses) {
      await _expenseBox!.delete(expense.id);
    }
  }

  List<SplitExpense> getExpensesByGroup(String groupId) {
    return _decodedExpenseValues()
        .where((expense) => expense.groupId == groupId)
        .toList();
  }

  Future<void> addExpense(SplitExpense expense) async {
    await init();
    await _expenseBox!.put(expense.id, expense.toJson());
  }

  Future<void> updateExpense(SplitExpense expense) async {
    await init();
    await _expenseBox!.put(expense.id, expense.toJson());
  }

  Future<void> deleteExpense(String id) async {
    await init();
    await _expenseBox!.delete(id);
  }

  List<SplitGroup> _decodedGroupValues() {
    final box = _currentGroupBoxOrNull();
    if (box == null) return [];
    return box.values.map(_decodeGroup).whereType<SplitGroup>().toList();
  }

  List<SplitExpense> _decodedExpenseValues() {
    final box = _currentExpenseBoxOrNull();
    if (box == null) return [];
    return box.values.map(_decodeExpense).whereType<SplitExpense>().toList();
  }

  SplitGroup? _decodeGroup(dynamic raw) {
    if (raw == null) return null;
    if (raw is SplitGroup) return raw;
    if (raw is Map) {
      return SplitGroup.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  SplitExpense? _decodeExpense(dynamic raw) {
    if (raw == null) return null;
    if (raw is SplitExpense) return raw;
    if (raw is Map) {
      return SplitExpense.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }
}
