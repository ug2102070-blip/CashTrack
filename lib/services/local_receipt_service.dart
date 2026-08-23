import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../core/utils/logger.dart';

/// LocalReceiptService manages saving, retrieving, and deleting transaction
/// receipt images locally inside the app's sandboxed document storage.
///
/// This provides 100% privacy, zero cloud storage costs, and instant offline access.
class LocalReceiptService {
  LocalReceiptService._internal();
  static final LocalReceiptService _instance = LocalReceiptService._internal();
  factory LocalReceiptService() => _instance;

  final ImagePicker _picker = ImagePicker();

  /// Picks an image from Camera or Gallery and saves it permanently to app documents directory
  Future<String?> pickAndSaveReceipt({
    required ImageSource source,
    String? customId,
    int imageQuality = 80,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
      );

      if (pickedFile == null) return null;

      return await saveReceiptLocally(pickedFile, customId: customId);
    } catch (e, stack) {
      AppLogger.e('Failed to pick and save receipt: $e\n$stack');
      return null;
    }
  }

  /// Copies an XFile permanently into the sandboxed `receipts/` directory
  Future<String?> saveReceiptLocally(XFile pickedFile, {String? customId}) async {
    try {
      if (kIsWeb) {
        return pickedFile.path;
      }

      final dir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${dir.path}/receipts');
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final id = customId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final ext = pickedFile.path.contains('.')
          ? '.${pickedFile.path.split('.').last}'
          : '.jpg';
      final fileName = 'receipt_${id}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final savedFile = File('${receiptsDir.path}/$fileName');

      final bytes = await pickedFile.readAsBytes();
      await savedFile.writeAsBytes(bytes, flush: true);

      AppLogger.i('Receipt saved permanently to local storage: ${savedFile.path}');
      return savedFile.path;
    } catch (e, stack) {
      AppLogger.e('Failed to save receipt locally: $e\n$stack');
      return null;
    }
  }

  /// Safely deletes a receipt file from device storage
  Future<bool> deleteReceipt(String? path) async {
    if (path == null || path.isEmpty || kIsWeb) return false;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        AppLogger.i('Deleted local receipt file: $path');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.w('Failed to delete receipt file: $e');
      return false;
    }
  }

  /// Checks if the receipt file exists on disk
  bool receiptExists(String? path) {
    if (path == null || path.isEmpty) return false;
    if (kIsWeb) return true;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }
}
