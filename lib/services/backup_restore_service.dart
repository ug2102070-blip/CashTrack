import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../data/repositories/hive_box_recovery.dart';
import 'telemetry_service.dart';

class BackupRestoreResult {
  final bool success;
  final String message;
  final Map<String, int> restoredCounts;
  final String? error;

  const BackupRestoreResult({
    required this.success,
    required this.message,
    this.restoredCounts = const {},
    this.error,
  });
}

class BackupRestoreService {
  BackupRestoreService._internal();
  static final BackupRestoreService _instance = BackupRestoreService._internal();
  factory BackupRestoreService() => _instance;

  static const int _currentSchemaVersion = 2;
  static const List<String> _collections = [
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

  /// Generates a complete JSON backup of all offline and synced financial records
  Future<String> generateBackupJson() async {
    final payload = <String, dynamic>{
      'app': AppConstants.appName,
      'schemaVersion': _currentSchemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'data': <String, dynamic>{},
    };

    final dataMap = payload['data'] as Map<String, dynamic>;
    int totalCount = 0;

    for (final collection in _collections) {
      final box = await _getBox(collection);
      final items = <Map<String, dynamic>>[];

      for (final entry in box.toMap().entries) {
        final itemMap = _safeMap(entry.value);
        if (itemMap != null) {
          items.add(itemMap);
        }
      }
      dataMap[collection] = items;
      totalCount += items.length;
    }

    payload['totalRecords'] = totalCount;
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Exports the backup file to disk and opens the system Share/Save sheet
  Future<String> exportBackupFile() async {
    try {
      final jsonContent = await generateBackupJson();
      final dir = await getApplicationDocumentsDirectory();
      final dateStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${dir.path}/cashtrack_backup_$dateStr.json');

      await file.writeAsString(jsonContent, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'CashTrack Full Encrypted Data Backup',
        ),
      );

      return 'Backup exported successfully (${file.path})';
    } catch (e, stack) {
      AppLogger.e('Export backup failed: $e');
      await TelemetryService.recordFailure(
        operation: 'backup_export',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Opens the device file picker and restores the selected backup JSON file
  Future<BackupRestoreResult> pickAndRestoreBackup({bool overwrite = true}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'ctbk', 'txt'],
      );

      if (result == null || result.files.isEmpty) {
        return const BackupRestoreResult(
          success: false,
          message: 'No backup file selected',
        );
      }

      final path = result.files.single.path;
      if (path == null) {
        // On web or platforms where path is null, use bytes
        final bytes = result.files.single.bytes;
        if (bytes == null) {
          return const BackupRestoreResult(
            success: false,
            message: 'Unable to read file content',
          );
        }
        final jsonString = utf8.decode(bytes);
        return restoreFromJsonString(jsonString, overwrite: overwrite);
      }

      final file = File(path);
      final jsonString = await file.readAsString();
      return restoreFromJsonString(jsonString, overwrite: overwrite);
    } catch (e, stack) {
      AppLogger.e('Restore from picked file failed: $e');
      await TelemetryService.recordFailure(
        operation: 'backup_restore',
        error: e,
        stackTrace: stack,
      );
      return BackupRestoreResult(
        success: false,
        message: 'Restore failed: $e',
        error: e.toString(),
      );
    }
  }

  /// Restores all collections from a JSON backup payload
  Future<BackupRestoreResult> restoreFromJsonString(
    String jsonString, {
    bool overwrite = true,
  }) async {
    try {
      final dynamic parsed = jsonDecode(jsonString);
      if (parsed is! Map<String, dynamic>) {
        return const BackupRestoreResult(
          success: false,
          message: 'Invalid backup file format',
        );
      }

      final data = parsed['data'] is Map ? Map<String, dynamic>.from(parsed['data'] as Map) : parsed;
      final restoredCounts = <String, int>{};

      for (final collection in _collections) {
        final rawList = data[collection];
        if (rawList is! List) continue;

        final box = await _getBox(collection);
        if (overwrite) {
          await box.clear();
        }

        int count = 0;
        for (final rawItem in rawList) {
          if (rawItem is! Map) continue;
          final item = Map<String, dynamic>.from(rawItem);
          final id = item['id']?.toString();
          if (id == null || id.isEmpty) continue;

          await box.put(id, item);
          count++;
        }
        restoredCounts[collection] = count;
      }

      AppLogger.i('Restore completed with counts: $restoredCounts');

      return BackupRestoreResult(
        success: true,
        message: 'Restore completed successfully',
        restoredCounts: restoredCounts,
      );
    } catch (e, stack) {
      AppLogger.e('Restore from JSON string failed: $e');
      await TelemetryService.recordFailure(
        operation: 'backup_json_parse',
        error: e,
        stackTrace: stack,
      );
      return BackupRestoreResult(
        success: false,
        message: 'Restore failed: $e',
        error: e.toString(),
      );
    }
  }

  Future<Box<dynamic>> _getBox(String name) => Hive.isBoxOpen(name)
      ? Future<Box<dynamic>>.value(Hive.box<dynamic>(name))
      : openBoxWithRecovery<dynamic>(name);

  Map<String, dynamic>? _safeMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    try {
      final json = value.toJson();
      return json is Map ? Map<String, dynamic>.from(json) : null;
    } catch (_) {
      return null;
    }
  }
}
