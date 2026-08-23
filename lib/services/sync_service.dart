import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

import '../core/utils/logger.dart';
import '../data/repositories/hive_box_recovery.dart';
import '../data/repositories/sync_tombstone_repository.dart';
import 'auth_service.dart';
import 'sync_conflict_resolver.dart';

/// Version 2 sync stores each record as its own document. This avoids the
/// Firestore 1 MiB document ceiling and permits record-level conflict handling.
class SyncService {
  SyncService._internal();
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;

  static const _schemaVersion = 2;
  static const _collections = <String>[
    'transactions',
    'categories',
    'accounts',
    'budgets',
    'goals',
    'debts',
    'assets',
    'investments',
    'split_groups',
    'split_expenses',
  ];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  Future<void> init() async {
    _connectivitySubscription ??= Connectivity().onConnectivityChanged.listen(
      (results) {
        if (results.any((result) => result != ConnectivityResult.none)) {
          unawaited(syncData());
        }
      },
    );
  }

  Future<String> syncData() async {
    final userId = AuthService().currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      return 'Sync skipped: sign in required';
    }
    try {
      await _migrateLegacySnapshot(userId);
      // Pull first so a fresh device never mistakes remote data for local deletes.
      await _pullRemote(userId);
      await _pushLocal(userId);
      return 'Sync complete';
    } catch (error, stackTrace) {
      AppLogger.e('Sync failed: $error\n$stackTrace');
      return 'Sync failed: $error';
    }
  }

  Future<String> backupToCloud() => syncData();
  Future<String> restoreLatestBackupFromCloud() async {
    final userId = AuthService().currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      return 'Restore skipped: sign in required';
    }
    try {
      await _migrateLegacySnapshot(userId);
      await _pullRemote(userId);
      return 'Restore complete';
    } catch (error) {
      return 'Restore failed: $error';
    }
  }

  DocumentReference<Map<String, dynamic>> _meta(String userId) =>
      _firestore.collection('users').doc(userId).collection('sync').doc('meta');

  CollectionReference<Map<String, dynamic>> _collection(
    String userId,
    String collection,
  ) =>
      _firestore.collection('users').doc(userId).collection(collection);

  Future<void> _migrateLegacySnapshot(String userId) async {
    final meta = await _meta(userId).get();
    if ((meta.data()?['schemaVersion'] as int?) == _schemaVersion) return;

    final legacy = await _firestore
        .collection('users')
        .doc(userId)
        .collection('app_data')
        .doc('snapshot')
        .get();
    final data =
        Map<String, dynamic>.from(legacy.data()?['data'] as Map? ?? {});
    final writes = <Future<void>>[];
    for (final collection in _collections) {
      final values = data[collection] as List? ?? const [];
      for (final raw in values) {
        if (raw is! Map) {
          continue;
        }
        final record = Map<String, dynamic>.from(raw);
        final id = record['id'];
        if (id is! String || id.isEmpty) continue;
        writes.add(_collection(userId, collection).doc(id).set(
              _outboundRecord(record, id),
              SetOptions(merge: true),
            ));
      }
    }
    await Future.wait(writes);
    await _meta(userId).set(<String, dynamic>{
      'schemaVersion': _schemaVersion,
      'migratedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> _pullRemote(String userId) async {
    for (final collection in _collections) {
      final box = await _box(collection);
      final snapshot = await _collection(userId, collection).get();
      for (final document in snapshot.docs) {
        final remote = _normalize(document.data());
        final local = _map(box.get(document.id));
        final shouldApplyRemote = SyncConflictResolver.shouldApplyRemote(
          remoteUpdatedAt:
              (remote['deletedAt'] ?? remote['updatedAt']) as String?,
          localUpdatedAt: local?['updatedAt'] as String?,
        );
        if (!shouldApplyRemote) {
          continue;
        }
        if (remote['isDeleted'] == true) {
          await box.delete(document.id);
        } else {
          await box.put(document.id, remote);
        }
      }
    }
  }

  Future<void> _pushLocal(String userId) async {
    final writes = <Future<void>>[];
    for (final collection in _collections) {
      final box = await _box(collection);
      for (final entry in box.toMap().entries) {
        final record = _map(entry.value);
        if (record == null) {
          continue;
        }
        final id = record['id'] is String
            ? record['id'] as String
            : entry.key.toString();
        writes.add(_collection(userId, collection).doc(id).set(
              _outboundRecord(record, id),
              SetOptions(merge: true),
            ));
      }
    }

    final tombstones = await SyncTombstoneRepository().box();
    final committedTombstones = <dynamic>[];
    for (final entry in tombstones.toMap().entries) {
      final tombstone = _map(entry.value);
      if (tombstone == null || tombstone['userId'] != userId) {
        continue;
      }
      final collection = tombstone['collection'];
      final id = tombstone['id'];
      if (collection is! String ||
          id is! String ||
          !_collections.contains(collection)) {
        continue;
      }
      writes.add(_collection(userId, collection).doc(id).set(<String, dynamic>{
        'id': id,
        'isDeleted': true,
        'deletedAt': tombstone['deletedAt'],
        'updatedAt': tombstone['deletedAt'],
      }, SetOptions(merge: true)));
      committedTombstones.add(entry.key);
    }
    await Future.wait(writes);
    for (final key in committedTombstones) {
      await tombstones.delete(key);
    }
  }

  Map<String, dynamic> _outboundRecord(Map<String, dynamic> record, String id) {
    final result = Map<String, dynamic>.from(record);
    result['id'] = id;
    result['updatedAt'] ??= DateTime.now().toUtc().toIso8601String();
    return result;
  }

  Future<Box<dynamic>> _box(String name) => Hive.isBoxOpen(name)
      ? Future<Box<dynamic>>.value(Hive.box<dynamic>(name))
      : openBoxWithRecovery<dynamic>(name);

  Map<String, dynamic>? _map(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    try {
      final json = value.toJson();
      return json is Map ? Map<String, dynamic>.from(json) : null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> value) => value.map(
        (key, item) => MapEntry(key, _normalizeValue(item)),
      );

  dynamic _normalizeValue(dynamic value) {
    if (value is Timestamp) return value.toDate().toUtc().toIso8601String();
    if (value is Map) {
      return value.map((key, item) => MapEntry(key, _normalizeValue(item)));
    }
    if (value is List) return value.map(_normalizeValue).toList();
    return value;
  }

  void dispose() => _connectivitySubscription?.cancel();
}
