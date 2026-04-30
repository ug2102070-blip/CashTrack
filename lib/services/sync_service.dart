import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/logger.dart';
import '../data/models/account_model.dart';
import '../data/models/asset_model.dart';
import '../data/models/budget_model.dart';
import '../data/models/category_model.dart';
import '../data/models/debt_model.dart';
import '../data/models/goal_model.dart';
import '../data/models/investment_model.dart';
import '../data/models/transaction_model.dart';
import 'auth_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const String _settingsBoxName = 'settingsBox';
  static const String _syncUserKey = 'sync_user_id';
  static const String _lastSyncKey = 'last_sync_at';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Future<void> init() async {
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        syncData();
      }
    });
  }

  Future<String> syncData() async {
    try {
      final userId = await _getSyncUserId();
      final snapshotRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('app_data')
          .doc('snapshot');

      final remoteDoc = await snapshotRef.get();
      final remoteUpdatedAt = _extractRemoteUpdatedAt(remoteDoc.data());
      final localLastSyncAt = await _getLocalLastSyncAt();

      if (remoteDoc.exists &&
          remoteUpdatedAt != null &&
          (localLastSyncAt == null ||
              remoteUpdatedAt.isAfter(localLastSyncAt))) {
        await _restoreFromRemote(remoteDoc.data());
        await _setLocalLastSyncAt(remoteUpdatedAt);
        AppLogger.i('Sync complete: Pulled latest backup from cloud');
        return 'Pulled latest backup from cloud';
      }

      final payload = await _buildLocalPayload();
      final now = DateTime.now().toUtc();

      await snapshotRef.set({
        'updated_at': Timestamp.fromDate(now),
        'version': 1,
        'data': payload,
      }, SetOptions(merge: true));

      await _setLocalLastSyncAt(now);
      AppLogger.i('Sync complete: Backed up local data to cloud');
      return 'Backed up local data to cloud';
    } catch (e) {
      AppLogger.e('Sync failed: $e');
      return 'Sync failed: $e';
    }
  }

  Future<String> backupToCloud() async {
    try {
      final userId = await _getSyncUserId();
      final snapshotRef = _snapshotRef(userId);
      final payload = await _buildLocalPayload();
      final now = DateTime.now().toUtc();

      await snapshotRef.set({
        'updated_at': Timestamp.fromDate(now),
        'version': 1,
        'data': payload,
      }, SetOptions(merge: true));

      await _setLocalLastSyncAt(now);
      AppLogger.i('Backup complete: Backed up local data to cloud');
      return 'Backed up local data to cloud';
    } catch (e) {
      AppLogger.e('Backup failed: $e');
      return 'Backup failed: $e';
    }
  }

  Future<String> restoreLatestBackupFromCloud() async {
    try {
      final userId = await _getSyncUserId();
      final snapshotRef = _snapshotRef(userId);
      final remoteDoc = await snapshotRef.get();
      if (!remoteDoc.exists || remoteDoc.data() == null) {
        return 'No cloud backup found';
      }

      final remoteUpdatedAt = _extractRemoteUpdatedAt(remoteDoc.data());
      await _restoreFromRemote(remoteDoc.data());
      if (remoteUpdatedAt != null) {
        await _setLocalLastSyncAt(remoteUpdatedAt);
      }
      AppLogger.i('Restore complete: Pulled latest backup from cloud');
      return 'Pulled latest backup from cloud';
    } catch (e) {
      AppLogger.e('Restore failed: $e');
      return 'Restore failed: $e';
    }
  }

  DateTime? _extractRemoteUpdatedAt(Map<String, dynamic>? data) {
    if (data == null) return null;
    final value = data['updated_at'];
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    return null;
  }

  Future<Map<String, dynamic>> _buildLocalPayload() async {
    final transactions = await _openBox<dynamic>('transactions');
    final categories = await _openBox<dynamic>('categories');
    final accounts = await _openBox<dynamic>('accounts');
    final budgets = await _openBox<dynamic>('budgets');
    final goals = await _openBox<dynamic>('goals');
    final debts = await _openBox<dynamic>('debts');
    final assets = await _openBox<dynamic>('assets');
    final investments = await _openBox<dynamic>('investments');

    return {
      'transactions': _jsonList(
        transactions.values,
        (map) => TransactionModel.fromJson(map),
      ),
      'categories': _jsonList(
        categories.values,
        (map) => CategoryModel.fromJson(map),
      ),
      'accounts': _jsonList(
        accounts.values,
        (map) => AccountModel.fromJson(map),
      ),
      'budgets': _jsonList(
        budgets.values,
        (map) => BudgetModel.fromJson(map),
      ),
      'goals': _jsonList(
        goals.values,
        (map) => GoalModel.fromJson(map),
      ),
      'debts': _jsonList(
        debts.values,
        (map) => DebtModel.fromJson(map),
      ),
      'assets': _jsonList(
        assets.values,
        (map) => AssetModel.fromJson(map),
      ),
      'investments': _jsonList(
        investments.values,
        (map) => InvestmentModel.fromJson(map),
      ),
    };
  }

  Future<void> _restoreFromRemote(Map<String, dynamic>? remoteData) async {
    if (remoteData == null) return;

    final data = Map<String, dynamic>.from(remoteData['data'] as Map? ?? {});

    final transactions = await _openBox<dynamic>('transactions');
    final categories = await _openBox<dynamic>('categories');
    final accounts = await _openBox<dynamic>('accounts');
    final budgets = await _openBox<dynamic>('budgets');
    final goals = await _openBox<dynamic>('goals');
    final debts = await _openBox<dynamic>('debts');
    final assets = await _openBox<dynamic>('assets');
    final investments = await _openBox<dynamic>('investments');

    await _mergeBoxData<TransactionModel>(
      box: transactions,
      rawList: data['transactions'] as List? ?? const [],
      fromJson: (map) => TransactionModel.fromJson(map),
      idOf: (item) => item.id,
    );

    await _mergeBoxData<CategoryModel>(
      box: categories,
      rawList: data['categories'] as List? ?? const [],
      fromJson: (map) => CategoryModel.fromJson(map),
      idOf: (item) => item.id,
    );

    await _mergeBoxData<AccountModel>(
      box: accounts,
      rawList: data['accounts'] as List? ?? const [],
      fromJson: (map) => AccountModel.fromJson(map),
      idOf: (item) => item.id,
    );

    await _mergeBoxData<BudgetModel>(
      box: budgets,
      rawList: data['budgets'] as List? ?? const [],
      fromJson: (map) => BudgetModel.fromJson(map),
      idOf: (item) => item.id,
    );

    await _mergeBoxData<GoalModel>(
      box: goals,
      rawList: data['goals'] as List? ?? const [],
      fromJson: (map) => GoalModel.fromJson(map),
      idOf: (item) => item.id,
    );

    await _mergeBoxData<DebtModel>(
      box: debts,
      rawList: data['debts'] as List? ?? const [],
      fromJson: (map) => DebtModel.fromJson(map),
      idOf: (item) => item.id,
    );

    await _mergeBoxData<AssetModel>(
      box: assets,
      rawList: data['assets'] as List? ?? const [],
      fromJson: (map) => AssetModel.fromJson(map),
      idOf: (item) => item.id,
    );

    await _mergeBoxData<InvestmentModel>(
      box: investments,
      rawList: data['investments'] as List? ?? const [],
      fromJson: (map) => InvestmentModel.fromJson(map),
      idOf: (item) => item.id,
    );
  }

  Future<void> _mergeBoxData<T>({
    required Box<dynamic> box,
    required List rawList,
    required T Function(Map<String, dynamic>) fromJson,
    required String Function(T) idOf,
  }) async {
    int inserted = 0;
    int updated = 0;
    int skipped = 0;

    for (final raw in rawList) {
      final map = Map<String, dynamic>.from(raw as Map);
      final remoteItem = fromJson(map);
      final itemId = idOf(remoteItem);
      final localItem = _decodeDynamic<T>(box.get(itemId), fromJson);

      if (localItem == null) {
        await box.put(itemId, _encodeDynamic(remoteItem));
        inserted++;
        continue;
      }

      final remoteTime = _extractItemTimestampFromMap(map);
      final localTime = _extractItemTimestampFromObject(localItem);

      if (_shouldApplyRemote(remoteTime: remoteTime, localTime: localTime)) {
        await box.put(itemId, _encodeDynamic(remoteItem));
        updated++;
      } else {
        skipped++;
      }
    }

    logStatus(
      'Merged ${box.name}: inserted=$inserted, updated=$updated, skipped=$skipped',
    );
  }

  bool _shouldApplyRemote({
    required DateTime? remoteTime,
    required DateTime? localTime,
  }) {
    if (remoteTime != null && localTime != null) {
      return !remoteTime.isBefore(localTime);
    }
    if (remoteTime != null && localTime == null) {
      return true;
    }
    if (remoteTime == null && localTime != null) {
      return false;
    }
    return false;
  }

  DateTime? _extractItemTimestampFromMap(Map<String, dynamic> map) {
    return _extractTimestampFromDynamic(
      map['updatedAt'] ?? map['createdAt'],
    );
  }

  DateTime? _extractItemTimestampFromObject(dynamic item) {
    try {
      final raw = item.toJson();
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        return _extractItemTimestampFromMap(map);
      }
    } catch (_) {
      // Keep null timestamp when shape is unknown.
    }
    return null;
  }

  DateTime? _extractTimestampFromDynamic(dynamic value) {
    if (value is DateTime) return value.toUtc();
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }

  Future<Box<T>> _openBox<T>(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<T>(name);
    }
    return Hive.openBox<T>(name);
  }

  List<Map<String, dynamic>> _jsonList<T>(
    Iterable<dynamic> values,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return values
        .map((raw) {
          final item = _decodeDynamic<T>(raw, fromJson);
          if (item == null) return null;
          final encoded = _encodeDynamic(item);
          return encoded is Map<String, dynamic> ? encoded : null;
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  T? _decodeDynamic<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null) return null;
    if (raw is T) return raw;
    if (raw is Map) {
      return fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  dynamic _encodeDynamic(dynamic item) {
    try {
      return item.toJson();
    } catch (_) {
      return item;
    }
  }

  Future<String> _getSyncUserId() async {
    final firebaseUid = AuthService().currentUser?.uid;
    if (firebaseUid != null && firebaseUid.isNotEmpty) {
      return firebaseUid;
    }

    final box = await _openBox<dynamic>(_settingsBoxName);
    final existing = box.get(_syncUserKey) as String?;
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = 'guest_${_uuid.v4()}';
    await box.put(_syncUserKey, generated);
    return generated;
  }

  DocumentReference<Map<String, dynamic>> _snapshotRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('app_data')
        .doc('snapshot');
  }

  Future<DateTime?> _getLocalLastSyncAt() async {
    final box = await _openBox<dynamic>(_settingsBoxName);
    final raw = box.get(_lastSyncKey);
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw)?.toUtc();
    }
    return null;
  }

  Future<void> _setLocalLastSyncAt(DateTime dateTime) async {
    final box = await _openBox<dynamic>(_settingsBoxName);
    await box.put(_lastSyncKey, dateTime.toIso8601String());
  }

  void logStatus(String message) {
    if (kDebugMode) {
      AppLogger.d('SyncService: $message');
    }
  }
}
