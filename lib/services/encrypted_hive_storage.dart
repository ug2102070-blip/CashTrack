import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// Owns Hive's at-rest encryption key and performs the one-time migration from
/// legacy plaintext boxes. The key never enters Hive or source control.
class EncryptedHiveStorage {
  EncryptedHiveStorage._();

  static const _keyName = 'cashtrack_hive_encryption_key_v1';
  static const _migrationName = 'cashtrack_hive_encryption_migrated_v1';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static HiveCipher? _cipher;

  static const boxes = <String>[
    'settingsBox',
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
    'sync_tombstones',
  ];

  static Future<void> prepare() async {
    if (kIsWeb || _cipher != null) return;

    var encodedKey = await _secureStorage.read(key: _keyName);
    if (encodedKey == null) {
      final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      encodedKey = base64UrlEncode(bytes);
      await _secureStorage.write(key: _keyName, value: encodedKey);
    }
    _cipher = HiveAesCipher(base64Url.decode(encodedKey));

    final migrated = await _secureStorage.read(key: _migrationName) == 'true';
    for (final boxName in boxes) {
      await _migrateBoxIfNeeded(boxName, migrated: migrated);
    }
    await _secureStorage.write(key: _migrationName, value: 'true');
  }

  static Future<Box<T>> openBox<T>(String name) {
    return Hive.openBox<T>(name, encryptionCipher: _cipher);
  }

  static Future<void> _migrateBoxIfNeeded(
    String boxName, {
    required bool migrated,
  }) async {
    if (!await Hive.boxExists(boxName) || Hive.isBoxOpen(boxName)) return;

    try {
      final encrypted = await openBox<dynamic>(boxName);
      await encrypted.close();
      return;
    } on HiveError {
      if (migrated) rethrow;
    }

    final legacy = await Hive.openBox<dynamic>(boxName);
    final data = Map<dynamic, dynamic>.from(legacy.toMap());
    await legacy.close();
    await Hive.deleteBoxFromDisk(boxName);
    final encrypted = await openBox<dynamic>(boxName);
    await encrypted.putAll(data);
    await encrypted.close();
  }
}
