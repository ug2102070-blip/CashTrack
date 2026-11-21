// lib/services/receipt_ocr_service.dart
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/utils/logger.dart';
import '../data/models/category_model.dart';
import 'local_receipt_service.dart';

class ReceiptScanResult {
  final double? amount;
  final String? merchant;
  final DateTime? date;
  final String? suggestedCategory;
  final String? itemsSummary;
  final String? imagePath;
  final bool isSuccess;
  final String? errorMessage;

  const ReceiptScanResult({
    this.amount,
    this.merchant,
    this.date,
    this.suggestedCategory,
    this.itemsSummary,
    this.imagePath,
    this.isSuccess = true,
    this.errorMessage,
  });

  factory ReceiptScanResult.failure(String message, {String? imagePath}) {
    return ReceiptScanResult(
      isSuccess: false,
      errorMessage: message,
      imagePath: imagePath,
    );
  }
}

class ReceiptOcrService {
  ReceiptOcrService._internal();
  static final ReceiptOcrService _instance = ReceiptOcrService._internal();
  factory ReceiptOcrService() => _instance;

  final LocalReceiptService _localReceiptService = LocalReceiptService();
  static const String _functionsRegion = 'us-central1';

  /// Captures an image and extracts receipt data using multimodal Vision Cloud Function
  Future<ReceiptScanResult?> scanReceipt({
    required ImageSource source,
    List<CategoryModel>? availableCategories,
  }) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 75,
      );

      if (pickedFile == null) return null;

      // 1. Save image permanently to local storage
      final localPath = await _localReceiptService.saveReceiptLocally(pickedFile);

      // 2. Read bytes for AI extraction
      final imageBytes = await pickedFile.readAsBytes();

      // 3. Extract receipt data via backend Vision Cloud Function
      final result = await _extractDataFromImageBytes(
        imageBytes: imageBytes,
        mimeType: pickedFile.mimeType ?? 'image/jpeg',
        availableCategories: availableCategories,
        localPath: localPath,
      );

      return result;
    } catch (e, stack) {
      AppLogger.e('Receipt scan failed: $e\n$stack');
      return ReceiptScanResult.failure('Failed to scan receipt: $e');
    }
  }

  Future<ReceiptScanResult> _extractDataFromImageBytes({
    required Uint8List imageBytes,
    required String mimeType,
    List<CategoryModel>? availableCategories,
    String? localPath,
  }) async {
    final catList = availableCategories?.map((c) => c.name).join(', ') ??
        'Food & Dining, Groceries, Shopping, Medical, Utilities, Transportation, Entertainment';

    try {
      final base64Img = base64Encode(imageBytes);
      final callable = FirebaseFunctions.instanceFor(
        region: _functionsRegion,
      ).httpsCallable(
        'scanReceipt',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 40)),
      );

      final result = await callable.call(<String, dynamic>{
        'imageBase64': base64Img,
        'mimeType': mimeType.contains('/') ? mimeType : 'image/jpeg',
        'categories': catList,
      });

      final resData = result.data;
      if (resData is Map && resData['data'] is Map) {
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(resData['data'] as Map);

        double? amount;
        if (data['amount'] != null) {
          if (data['amount'] is num) {
            amount = (data['amount'] as num).toDouble();
          } else if (data['amount'] is String) {
            amount = double.tryParse(
              (data['amount'] as String).replaceAll(',', ''),
            );
          }
        }

        DateTime? date;
        if (data['date'] != null && data['date'] is String) {
          date = DateTime.tryParse(data['date'] as String);
        }

        return ReceiptScanResult(
          amount: amount,
          merchant: data['merchant'] as String?,
          date: date,
          suggestedCategory: data['category'] as String?,
          itemsSummary: data['itemsSummary'] as String?,
          imagePath: localPath,
          isSuccess: true,
        );
      }
    } catch (e) {
      AppLogger.w('Cloud scanReceipt failed: $e. Returning fallback with saved image.');
    }

    // Fallback: If AI is offline or unavailable, user still has their attached receipt photo!
    return ReceiptScanResult(
      imagePath: localPath,
      isSuccess: true,
    );
  }
}
