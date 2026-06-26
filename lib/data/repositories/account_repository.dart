import 'package:hive/hive.dart';

import '../models/account_model.dart';
import 'hive_box_recovery.dart';
import '../../services/auth_service.dart';

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

  // Get current user ID for filtering
  String? _getCurrentUserId() {
    final authService = AuthService();
    return authService.currentUser?.uid;
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
    final userId = _getCurrentUserId();

    // Check if the user already has any accounts. If they do, do not re-seed default accounts.
    final userAccounts = _decodedValues().where((a) => a.userId == userId).toList();
    if (userAccounts.isNotEmpty) {
      return;
    }

    // Each user gets their own default accounts with user-specific keys
    for (final account in DefaultAccounts.accounts) {
      // Use user-specific key so each user has isolated default accounts
      final userSpecificId =
          userId != null ? '${account.id}_$userId' : account.id;
      final legacyExisting = userId == null ? null : _decode(box.get(account.id));
      if (legacyExisting != null &&
          legacyExisting.userId == userId &&
          _decode(box.get(userSpecificId)) == null) {
        await box.put(
          userSpecificId,
          legacyExisting.copyWith(id: userSpecificId).toJson(),
        );
        await box.delete(account.id);
      }

      final rawExisting = box.get(userSpecificId);
      final existing = _decode(rawExisting);
      if (existing == null) {
        final userAccount = account.copyWith(
          id: userSpecificId,
          userId: userId,
        );
        await box.put(userSpecificId, userAccount.toJson());
        continue;
      }

      final normalized = existing.copyWith(
        name: account.name,
        nameBn: account.nameBn,
        type: account.type,
        icon: account.icon,
        colorHex: account.colorHex,
        isDefault: true,
        userId: userId,
        updatedAt: DateTime.now(),
      );

      if (normalized != existing) {
        await box.put(userSpecificId, normalized.toJson());
      }
    }

    await _removeEmptyDuplicateDefaults(box, userId);
  }

  List<AccountModel> getAllAccounts() {
    final userId = _getCurrentUserId();
    // Strictly show only this user's accounts (default or custom)
    return _dedupeDefaultAccounts(
      _decodedValues().where((a) => a.userId == userId).toList(),
      userId,
    );
  }

  AccountModel? getAccountById(String id) {
    final userId = _getCurrentUserId();
    // Try user-specific key first (for default accounts)
    final userSpecificId =
        userId != null && !id.endsWith('_$userId') ? '${id}_$userId' : id;
    AccountModel? account = _decode(_currentBoxOrNull()?.get(userSpecificId));
    // Fallback to original id
    account ??= _decode(_currentBoxOrNull()?.get(id));
    if (account == null) return null;

    // Allow access only to this user's accounts
    if (account.userId == userId) return account;
    return null;
  }

  Future<void> addAccount(AccountModel account) async {
    await init();
    final userId = _getCurrentUserId();
    final accountWithUser = account.copyWith(userId: userId);
    await _box!.put(accountWithUser.id, accountWithUser.toJson());
  }

  Future<void> updateAccount(AccountModel account) async {
    await init();
    final userId = _getCurrentUserId();
    final accountWithUser = account.copyWith(userId: userId);
    await _box!.put(accountWithUser.id, accountWithUser.toJson());
  }

  Future<void> updateBalance(String accountId, double newBalance) async {
    await init();
    final account = _decode(_box!.get(accountId));
    if (account != null) {
      // Only update if it's a default account or user's account
      final userId = _getCurrentUserId();
      if (account.isDefault ||
          account.userId == null ||
          account.userId == userId) {
        await _box!.put(
          accountId,
          account
              .copyWith(balance: newBalance, updatedAt: DateTime.now())
              .toJson(),
        );
      }
    }
  }

  Future<void> deleteAccount(String id) async {
    await init();
    await _box!.delete(id);
  }

  double getTotalBalance() {
    final userId = _getCurrentUserId();
    // Strictly filter by current user only
    return _dedupeDefaultAccounts(
      _decodedValues().where((a) => a.userId == userId).toList(),
      userId,
    )
        .fold<double>(0, (sum, account) => sum + account.balance);
  }

  List<AccountModel> _dedupeDefaultAccounts(
    List<AccountModel> accounts,
    String? userId,
  ) {
    final selectedDefaults = <String, AccountModel>{};
    final customAccounts = <AccountModel>[];

    for (final account in accounts) {
      final defaultId = _matchingDefaultId(account);
      if (defaultId == null) {
        customAccounts.add(account);
        continue;
      }

      final current = selectedDefaults[defaultId];
      if (current == null ||
          _defaultRank(account, userId) > _defaultRank(current, userId)) {
        selectedDefaults[defaultId] = account;
      }
    }

    return [...selectedDefaults.values, ...customAccounts];
  }

  int _defaultRank(AccountModel account, String? userId) {
    var rank = 0;
    if (userId != null && account.id.endsWith('_$userId')) rank += 4;
    if (account.balance != 0) rank += 2;
    if (account.updatedAt != null) rank += 1;
    return rank;
  }

  Future<void> _removeEmptyDuplicateDefaults(
    Box<dynamic> box,
    String? userId,
  ) async {
    if (userId == null) return;

    for (final account in DefaultAccounts.accounts) {
      final userSpecificId = '${account.id}_$userId';
      final userSpecific = _decode(box.get(userSpecificId));
      final legacy = _decode(box.get(account.id));
      if (userSpecific == null || legacy == null) continue;
      if (legacy.userId != userId || legacy.balance != 0) continue;
      await box.delete(account.id);
    }
  }

  String? _matchingDefaultId(AccountModel account) {
    if (!account.isDefault) return null;
    for (final defaultAccount in DefaultAccounts.accounts) {
      if (account.id == defaultAccount.id ||
          account.id.startsWith('${defaultAccount.id}_')) {
        return defaultAccount.id;
      }
    }
    return null;
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
