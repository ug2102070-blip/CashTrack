import 'package:hive/hive.dart';

import '../models/debt_model.dart';
import 'hive_box_recovery.dart';

class DebtRepository {
  DebtRepository._internal();
  static final DebtRepository _instance = DebtRepository._internal();
  factory DebtRepository() => _instance;

  static const String _boxName = 'debts';
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

  List<DebtModel> getAllDebts() {
    return _decodedValues();
  }

  List<DebtModel> getActiveDebts() {
    return _decodedValues().where((debt) => !debt.isSettled).toList();
  }

  List<DebtModel> getLentMoney() {
    return _decodedValues()
        .where((debt) => debt.type == DebtType.lent && !debt.isSettled)
        .toList();
  }

  List<DebtModel> getBorrowedMoney() {
    return _decodedValues()
        .where((debt) => debt.type == DebtType.borrowed && !debt.isSettled)
        .toList();
  }

  Future<void> addDebt(DebtModel debt) async {
    await init();
    await _box!.put(debt.id, debt.toJson());
  }

  Future<void> updateDebt(DebtModel debt) async {
    await init();
    await _box!.put(debt.id, debt.toJson());
  }

  Future<void> updatePayment(String debtId, double paidAmount) async {
    await init();
    final debt = _decode(_box!.get(debtId));
    if (debt != null) {
      final isSettled = paidAmount >= debt.amount;
      await _box!.put(
        debtId,
        debt
            .copyWith(
              paidAmount: paidAmount,
              isSettled: isSettled,
              updatedAt: DateTime.now(),
            )
            .toJson(),
      );
    }
  }

  Future<void> deleteDebt(String id) async {
    await init();
    await _box!.delete(id);
  }

  List<DebtModel> _decodedValues() {
    final box = _currentBoxOrNull();
    if (box == null) return [];
    return box.values.map(_decode).whereType<DebtModel>().toList();
  }

  DebtModel? _decode(dynamic raw) {
    if (raw == null) return null;
    if (raw is DebtModel) return raw;
    if (raw is Map) {
      return DebtModel.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }
}
