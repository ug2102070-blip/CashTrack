import 'package:hive/hive.dart';

import '../models/investment_model.dart';
import 'hive_box_recovery.dart';

class InvestmentRepository {
  InvestmentRepository._internal();
  static final InvestmentRepository _instance =
      InvestmentRepository._internal();
  factory InvestmentRepository() => _instance;

  static const String _boxName = 'investments';
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

  List<InvestmentModel> getAllInvestments() {
    return _decodedValues();
  }

  List<InvestmentModel> getInvestmentsByType(InvestmentType type) {
    return _decodedValues()
        .where((investment) => investment.type == type)
        .toList();
  }

  InvestmentModel? getInvestmentById(String id) {
    return _decode(_currentBoxOrNull()?.get(id));
  }

  Future<void> addInvestment(InvestmentModel investment) async {
    await init();
    await _box!.put(investment.id, investment.toJson());
  }

  Future<void> updateInvestment(InvestmentModel investment) async {
    await init();
    await _box!.put(investment.id, investment.toJson());
  }

  Future<void> updateCurrentValue(String investmentId, double newValue) async {
    await init();
    final investment = _decode(_box!.get(investmentId));
    if (investment != null) {
      await _box!.put(
        investmentId,
        investment
            .copyWith(currentValue: newValue, updatedAt: DateTime.now())
            .toJson(),
      );
    }
  }

  Future<void> deleteInvestment(String id) async {
    await init();
    await _box!.delete(id);
  }

  double getTotalInvested() {
    return _decodedValues()
        .fold<double>(0, (sum, inv) => sum + inv.investedAmount);
  }

  double getTotalCurrentValue() {
    return _decodedValues()
        .fold<double>(0, (sum, inv) => sum + inv.currentValue);
  }

  double getTotalReturns() {
    return getTotalCurrentValue() - getTotalInvested();
  }

  double getReturnPercentage() {
    final invested = getTotalInvested();
    if (invested == 0) return 0;
    return ((getTotalCurrentValue() - invested) / invested) * 100;
  }

  Map<InvestmentType, double> getInvestmentsByTypeBreakdown() {
    final Map<InvestmentType, double> breakdown = {};

    for (final investment in _decodedValues()) {
      breakdown[investment.type] =
          (breakdown[investment.type] ?? 0) + investment.currentValue;
    }

    return breakdown;
  }

  List<InvestmentModel> _decodedValues() {
    final box = _currentBoxOrNull();
    if (box == null) return [];
    return box.values.map(_decode).whereType<InvestmentModel>().toList();
  }

  InvestmentModel? _decode(dynamic raw) {
    if (raw == null) return null;
    if (raw is InvestmentModel) return raw;
    if (raw is Map) {
      return InvestmentModel.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }
}
