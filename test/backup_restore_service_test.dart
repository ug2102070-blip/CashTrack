import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:cashtrack/services/backup_restore_service.dart';

import 'hive_test_setup.dart';

void main() {
  setUpAll(() async {
    await initializeCashtrackRepositoriesForWidgetTest();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  test('BackupRestoreService generates valid JSON backup and restores records', () async {
    final service = BackupRestoreService();

    // 1. Put some sample data in accounts and transactions
    final accountBox = Hive.box('accounts');
    await accountBox.put('acc_test_1', {
      'id': 'acc_test_1',
      'name': 'Bkash Primary',
      'type': 'bkash',
      'balance': 50000, // 500 BDT in paisa
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });

    final txBox = Hive.box('transactions');
    await txBox.put('tx_test_1', {
      'id': 'tx_test_1',
      'type': 'expense',
      'amount': 15000, // 150 BDT in paisa
      'categoryId': 'food',
      'accountId': 'acc_test_1',
      'date': DateTime.now().toUtc().toIso8601String(),
      'note': 'Dinner with team',
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });

    // 2. Generate backup JSON
    final jsonBackup = await service.generateBackupJson();
    expect(jsonBackup, isNotEmpty);

    final decoded = jsonDecode(jsonBackup) as Map<String, dynamic>;
    expect(decoded['app'], 'CashTrack');
    expect(decoded['schemaVersion'], 2);
    expect(decoded['data'], isA<Map>());

    final data = decoded['data'] as Map<String, dynamic>;
    expect(data['accounts'], isA<List>());
    expect(data['transactions'], isA<List>());

    // 3. Clear boxes and restore
    await accountBox.clear();
    await txBox.clear();
    expect(accountBox.isEmpty, isTrue);
    expect(txBox.isEmpty, isTrue);

    final restoreResult = await service.restoreFromJsonString(jsonBackup, overwrite: true);
    expect(restoreResult.success, isTrue);
    expect(restoreResult.restoredCounts['accounts'], greaterThanOrEqualTo(1));
    expect(restoreResult.restoredCounts['transactions'], greaterThanOrEqualTo(1));

    // 4. Verify restored record integrity
    expect(accountBox.containsKey('acc_test_1'), isTrue);
    expect(txBox.containsKey('tx_test_1'), isTrue);
  });

  test('BackupRestoreService handles invalid JSON payloads gracefully without crashing', () async {
    final service = BackupRestoreService();

    final result = await service.restoreFromJsonString('invalid json {}{');
    expect(result.success, isFalse);
    expect(result.message, contains('Restore failed'));
  });
}
