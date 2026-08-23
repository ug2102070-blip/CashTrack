import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:cashtrack/data/repositories/sync_tombstone_repository.dart';
import 'package:cashtrack/services/sync_conflict_resolver.dart';

import 'hive_test_setup.dart';

void main() {
  setUpAll(initializeHiveForTests);

  setUp(() async {
    if (Hive.isBoxOpen('sync_tombstones')) {
      await Hive.box('sync_tombstones').clear();
    }
  });

  test('newer local edit is not overwritten by stale remote data', () {
    expect(
      SyncConflictResolver.shouldApplyRemote(
        remoteUpdatedAt: '2026-08-10T10:00:00.000Z',
        localUpdatedAt: '2026-08-10T10:01:00.000Z',
      ),
      isFalse,
    );
  });

  test('remote tombstone wins when it is newer than the local record', () {
    expect(
      SyncConflictResolver.shouldApplyRemote(
        remoteUpdatedAt: '2026-08-10T10:02:00.000Z',
        localUpdatedAt: '2026-08-10T10:01:00.000Z',
      ),
      isTrue,
    );
  });

  test('offline deletion is persisted until sync acknowledges it', () async {
    await SyncTombstoneRepository().record(
      'accounts',
      'account-1',
      forUserId: 'user-1',
    );
    final box = await SyncTombstoneRepository().box();
    final tombstone = Map<String, dynamic>.from(
      box.get('user-1:accounts:account-1') as Map,
    );
    expect(tombstone['userId'], 'user-1');
    expect(tombstone['collection'], 'accounts');
    expect(tombstone['id'], 'account-1');
    expect(tombstone['deletedAt'], isNotEmpty);
  });
}
