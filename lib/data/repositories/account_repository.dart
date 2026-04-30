import 'package:hive/hive.dart';

import '../models/account_model.dart';
import 'hive_box_recovery.dart';

class AccountRepository {
  AccountRepository._internal();
  static final AccountRepository _instance = AccountRepository._internal();
  factory AccountRepository() => _instance;

  static const String _boxName = 'accounts';
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
    if (_initialized && _box == null && Hive.isBoxOpen(_boxName)) {
      _box = Hive.box(_boxName);
    } else if (!_initialized || _box == null) {
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box(_boxName);
      } else {
        _box = await openBoxWithRecovery<dynamic>(_boxName);
      }
    }

    await _ensureDefaultAccounts();
    _initialized = true;
  }

  Future<void> _ensureDefaultAccounts() async {
    final box = _currentBoxOrNull();
    if (box == null) return;
    for (final account in DefaultAccounts.accounts) {
      final rawExisting = box.get(account.id);
      final existing = _decode(rawExisting);
      if (existing == null) {
        await box.put(account.id, account.toJson());
        continue;
      }

      final normalized = existing.copyWith(
        name: account.name,
        nameBn: account.nameBn,
        type: account.type,
        icon: account.icon,
        colorHex: account.colorHex,
        isDefault: true,
        updatedAt: DateTime.now(),
      );

      if (normalized != existing) {
        await box.put(account.id, normalized.toJson());
      }
    }
  }

  List<AccountModel> getAllAccounts() {
    return _decodedValues();
  }

  AccountModel? getAccountById(String id) {
    return _decode(_currentBoxOrNull()?.get(id));
  }

  Future<void> addAccount(AccountModel account) async {
    await init();
    await _box!.put(account.id, account.toJson());
  }

  Future<void> updateAccount(AccountModel account) async {
    await init();
    await _box!.put(account.id, account.toJson());
  }

  Future<void> updateBalance(String accountId, double newBalance) async {
    await init();
    final account = _decode(_box!.get(accountId));
    if (account != null) {
      await _box!.put(
        accountId,
        account
            .copyWith(balance: newBalance, updatedAt: DateTime.now())
            .toJson(),
      );
    }
  }

  Future<void> deleteAccount(String id) async {
    await init();
    final account = _decode(_box!.get(id));
    if (account != null && account.isDefault) return;
    await _box!.delete(id);
  }

  double getTotalBalance() {
    return _decodedValues()
        .fold<double>(0, (sum, account) => sum + account.balance);
  }

  List<AccountModel> _decodedValues() {
    final box = _currentBoxOrNull();
    if (box == null) return [];
    return box.values.map(_decode).whereType<AccountModel>().toList();
  }

  AccountModel? _decode(dynamic raw) {
    if (raw == null) return null;
    if (raw is AccountModel) return raw;
    if (raw is Map) {
      return AccountModel.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }
}
