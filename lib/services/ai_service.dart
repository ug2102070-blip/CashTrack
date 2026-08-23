import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

import '../core/l10n/app_l10n.dart';
import '../core/utils/logger.dart';

/// Sends finance-assistant requests only through the protected backend.
///
/// Provider keys must never be embedded in an app binary or sent from a
/// device. The Cloud Function enforces Firebase Authentication, App Check,
/// payload limits, and per-user rate limits before it calls the AI provider.
class AiService {
  static const String _functionsRegion = 'us-central1';
  static const String _settingsBoxName = 'settingsBox';
  static const String _legacyApiKeySettingKey = 'geminiApiKey';
  static const String _legacySecureApiKeyKey = 'gemini_api_key_secure';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  bool get isConfigured => true;

  /// Removes keys saved by older app versions. Keeping a user-supplied AI key
  /// in browser storage is not a safe production design.
  Future<void> init() async {
    try {
      if (kIsWeb) {
        final box = Hive.isBoxOpen(_settingsBoxName)
            ? Hive.box(_settingsBoxName)
            : await Hive.openBox(_settingsBoxName);
        await box.delete(_legacyApiKeySettingKey);
      } else {
        await _secureStorage.delete(key: _legacySecureApiKeyKey);
        if (Hive.isBoxOpen(_settingsBoxName)) {
          await Hive.box(_settingsBoxName).delete(_legacyApiKeySettingKey);
        }
      }
    } catch (error) {
      // A cleanup failure must not block app start. No key is read or used.
      AppLogger.w('Unable to remove legacy AI credentials: $error');
    }
  }

  Future<String> getResponse(
    String query, {
    String? financialContext,
    AppL10n? l10n,
  }) async {
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: _functionsRegion,
      ).httpsCallable(
        'generateAiResponse',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 35)),
      );

      final result = await callable.call(<String, String>{
        'query': query,
        'financialContext': financialContext ?? '',
      });
      final data = result.data;
      if (data is Map && data['text'] is String) {
        final text = (data['text'] as String).trim();
        if (text.isNotEmpty) return text;
      }
      return l10n?.t('ai_service_no_response') ??
          'No response from AI service.';
    } on FirebaseFunctionsException catch (error) {
      AppLogger.w('AI backend rejected request: ${error.code}');
      if (error.code == 'resource-exhausted') {
        return 'AI request limit reached. Please try again in a minute.';
      }
      if (error.code == 'unauthenticated' ||
          error.code == 'permission-denied') {
        return 'Please sign in with a verified account to use the AI assistant.';
      }
      if (error.code == 'invalid-argument') {
        return 'Your AI request is too large or invalid. Please shorten it.';
      }
      return l10n?.t('ai_service_error_api_key') ??
          'AI service is temporarily unavailable. Please try again later.';
    } catch (error) {
      AppLogger.w('AI backend request failed: $error');
      return l10n?.t('ai_service_error_api_key') ??
          'AI service is temporarily unavailable. Please try again later.';
    }
  }

  Future<String> analyzeBudget({
    double? income,
    double? expense,
    String? currency,
    AppL10n? l10n,
  }) {
    final cur = currency ?? 'BDT';
    final prompt = income != null && expense != null
        ? 'Analyze this budget. Income: $income $cur, Expense: $expense $cur. '
            'Give a short summary and one actionable tip.'
        : 'Analyze my budget and give one actionable tip.';
    return getResponse(prompt, l10n: l10n);
  }

  Future<List<String>> getSuggestions() async => const <String>[
        'How is my spending this month?',
        'Show me budget breakdown',
        'Tips for saving money',
      ];
}
