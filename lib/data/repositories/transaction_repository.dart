import 'package:hive/hive.dart';

import '../models/transaction_model.dart';
import 'hive_box_recovery.dart';

class TransactionRepository {
  TransactionRepository._internal();
  static final TransactionRepository _instance =
      TransactionRepository._internal();
  factory TransactionRepository() => _instance;

  static const String _boxName = 'transactions';
  Box<dynamic>? _box;
  bool _initialized = false;

  bool get isInitialized => _initialized && _box != null;

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

  List<TransactionModel> getAllTransactions() {
    return _decodedValues().where((t) => !t.isDeleted).toList();
  }

  List<TransactionModel> getRecentTransactions({int limit = 10}) {
    final all = getAllTransactions()..sort((a, b) => b.date.compareTo(a.date));
    return all.take(limit).toList();
  }

  List<TransactionModel> getTransactionsByType(TransactionType type) {
    return _decodedValues()
        .where((t) => !t.isDeleted && t.type == type)
        .toList();
  }

  List<TransactionModel> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return _decodedValues()
        .where((t) =>
            !t.isDeleted &&
            t.date.isAfter(start.subtract(const Duration(days: 1))) &&
            t.date.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await init();
    await _box!.put(transaction.id, transaction.toJson());
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await init();
    await _box!.put(transaction.id, transaction.toJson());
  }

  Future<void> deleteTransaction(String id) async {
    await init();
    final transaction = _decode(_box!.get(id));
    if (transaction != null) {
      await _box!.put(
        id,
        transaction
            .copyWith(isDeleted: true, updatedAt: DateTime.now())
            .toJson(),
      );
    }
  }

  double getTotalIncome({DateTime? start, DateTime? end}) {
    var transactions = _decodedValues()
        .where((t) => !t.isDeleted && t.type == TransactionType.income);

    if (start != null && end != null) {
      transactions = transactions.where((t) =>
          t.date.isAfter(start.subtract(const Duration(days: 1))) &&
          t.date.isBefore(end.add(const Duration(days: 1))));
    }

    return transactions.fold<double>(0, (sum, t) => sum + t.amount);
  }

  double getTotalExpense({DateTime? start, DateTime? end}) {
    var transactions = _decodedValues()
        .where((t) => !t.isDeleted && t.type == TransactionType.expense);

    if (start != null && end != null) {
      transactions = transactions.where((t) =>
          t.date.isAfter(start.subtract(const Duration(days: 1))) &&
          t.date.isBefore(end.add(const Duration(days: 1))));
    }

    return transactions.fold<double>(0, (sum, t) => sum + t.amount);
  }

  List<TransactionModel> _decodedValues() {
    final box = _currentBoxOrNull();
    if (box == null) return [];
    return box.values.map(_decode).whereType<TransactionModel>().toList();
  }

  TransactionModel? _decode(dynamic raw) {
    if (raw == null) return null;
    if (raw is TransactionModel) return raw;
    if (raw is Map) {
      return TransactionModel.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }
}
