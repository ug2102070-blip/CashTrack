import 'package:hive/hive.dart';

import '../../services/auth_service.dart';
import 'hive_box_recovery.dart';

/// Durable deletion intents prevent stale remote data from reviving an offline
/// delete on another device.
class SyncTombstoneRepository {
  SyncTombstoneRepository._();
  static final SyncTombstoneRepository _instance = SyncTombstoneRepository._();
  factory SyncTombstoneRepository() => _instance;

  static const _boxName = 'sync_tombstones';

  Future<void> record(String collection, String id, {String? forUserId}) async {
    final userId = forUserId ?? AuthService().currentUser?.uid;
    if (userId == null || userId.isEmpty) return;
    final box = Hive.isBoxOpen(_boxName)
        ? Hive.box<dynamic>(_boxName)
        : await openBoxWithRecovery<dynamic>(_boxName);
    await box.put('$userId:$collection:$id', <String, dynamic>{
      'userId': userId,
      'collection': collection,
      'id': id,
      'deletedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<Box<dynamic>> box() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box<dynamic>(_boxName);
    return openBoxWithRecovery<dynamic>(_boxName);
  }
}
