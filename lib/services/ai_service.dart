// lib/services/ai_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

import '../core/l10n/app_l10n.dart';
import '../core/utils/logger.dart';

class AiService {
  AiService({String? apiKey}) : _explicitKey = apiKey;

  // Removed compile-time _useBackend flag — it always evaluated to true at
  // runtime even when USE_AI_BACKEND was not set, causing the "check backend
  // configuration" error.  We now prefer the stored API key and only fall back
  // to Firebase Functions when explicitly requested via dart-define.
  static const bool _useBackendOverride =
      bool.fromEnvironment('USE_AI_BACKEND', defaultValue: false);
  static const String _defaultModel = 'gemini-2.0-flash';
  static const String _functionsRegion = 'us-central1';
  static const String _settingsBoxName = 'settingsBox';
  static const String _apiKeySettingKey = 'geminiApiKey';
  static const String _secureApiKeyKey = 'gemini_api_key_secure';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// In-memory cache so the sync getter can work without awaiting.
  static String _cachedApiKey = '';

  /// Key passed directly at construction (e.g. via --dart-define compile flag)
  final String? _explicitKey;
  final Dio _dio = Dio();

  /// Reads the cached API key (populated by [init] or [loadApiKey]).
  String _storedKey() {
    return _cachedApiKey;
  }

  /// Returns the effective API key: explicit > dart-define > stored in settings.
  String get _apiKey {
    final explicit = _explicitKey;
    if (explicit != null && explicit.trim().isNotEmpty) {
      return explicit.trim();
    }
    const envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (envKey.trim().isNotEmpty) return envKey.trim();
    return _storedKey().trim();
  }

  bool get isConfigured => _useBackendOverride || _apiKey.isNotEmpty;

  Future<String> _getEffectiveApiKey() async {
    final explicit = _explicitKey;
    if (explicit != null && explicit.trim().isNotEmpty) {
      return explicit.trim();
    }

    const envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (envKey.trim().isNotEmpty) return envKey.trim();

    return (await loadApiKey()).trim();
  }

  /// Pre-loads the API key from secure storage into the in-memory cache.
  /// Call this once at app startup.
  Future<void> init() async {
    _cachedApiKey = await loadApiKey();
  }

  /// Saves a Gemini API key — secure storage on native, Hive on web.
  static Future<void> saveApiKey(String key) async {
    final trimmed = key.trim();
    if (kIsWeb) {
      // Web: flutter_secure_storage has no hardware-backed encryption,
      // fall back to Hive.
      final box = Hive.isBoxOpen(_settingsBoxName)
          ? Hive.box(_settingsBoxName)
          : await Hive.openBox(_settingsBoxName);
      await box.put(_apiKeySettingKey, trimmed);
    } else {
      await _secureStorage.write(key: _secureApiKeyKey, value: trimmed);
      // Clean up old plain-text Hive copy if it exists.
      try {
        final box = Hive.isBoxOpen(_settingsBoxName)
            ? Hive.box(_settingsBoxName)
            : await Hive.openBox(_settingsBoxName);
        if (box.containsKey(_apiKeySettingKey)) {
          await box.delete(_apiKeySettingKey);
        }
      } catch (_) {}
    }
    _cachedApiKey = trimmed;
  }

  /// Reads the saved Gemini API key — secure storage on native, Hive on web.
  static Future<String> loadApiKey() async {
    if (kIsWeb) {
      final box = Hive.isBoxOpen(_settingsBoxName)
          ? Hive.box(_settingsBoxName)
          : await Hive.openBox(_settingsBoxName);
      final key = (box.get(_apiKeySettingKey) as String?) ?? '';
      _cachedApiKey = key;
      return key;
    } else {
      // Try secure storage first, then fall back to Hive for migration.
      final secureKey = await _secureStorage.read(key: _secureApiKeyKey) ?? '';
      if (secureKey.isNotEmpty) {
        _cachedApiKey = secureKey;
        return secureKey;
      }
      // Migration: read from old Hive location, move to secure storage.
      try {
        final box = Hive.isBoxOpen(_settingsBoxName)
            ? Hive.box(_settingsBoxName)
            : await Hive.openBox(_settingsBoxName);
        final hiveKey = (box.get(_apiKeySettingKey) as String?) ?? '';
        if (hiveKey.isNotEmpty) {
          await _secureStorage.write(key: _secureApiKeyKey, value: hiveKey);
          await box.delete(_apiKeySettingKey);
          _cachedApiKey = hiveKey;
          return hiveKey;
        }
      } catch (_) {}
      _cachedApiKey = '';
      return '';
    }
  }

  Future<String> getResponse(
    String query, {
    String? financialContext,
    AppL10n? l10n,
  }) async {
    try {
      final effectiveApiKey = await _getEffectiveApiKey();

      // Priority 1: Direct Gemini API (user's own key — most reliable path)
      if (effectiveApiKey.isNotEmpty) {
        return await _getResponseFromGemini(
          query: query,
          financialContext: financialContext,
          l10n: l10n,
          apiKey: effectiveApiKey,
        );
      }

      // Priority 2: Firebase Cloud Functions backend (optional, needs deployment)
      if (_useBackendOverride) {
        try {
          return await _getResponseFromBackend(
            query: query,
            financialContext: financialContext,
            l10n: l10n,
          );
        } catch (e) {
          AppLogger.w('AiService: Firebase backend failed: $e');
          rethrow;
        }
      }

      // No key and no backend → guide user
      return l10n?.t('ai_service_not_configured') ??
          'AI service is not configured. Please set your Gemini API key in Settings → AI Assistant.';
    } catch (e) {
      AppLogger.e('AiService error: $e');
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 429) {
          return 'API Quota Exceeded: Your API key has reached its request limit. Please check your quota.';
        } else if (statusCode == 400) {
          return 'API Error: Bad request. Please check if the API key is correct.';
        } else if (statusCode == 401 || statusCode == 403) {
          return 'API Error: Invalid API key or permission denied. Please check your settings.';
        } else if (statusCode == 404) {
          return 'API Error: Model version not found or deprecated.';
        }
      }
      return l10n?.t('ai_service_error_api_key') ??
          'AI service error. Please check your Gemini API key in Settings → AI Assistant.';
    }
  }

  Future<String> analyzeBudget({
    double? income,
    double? expense,
    String? currency,
    AppL10n? l10n,
  }) async {
    final cur = currency ?? 'BDT';
    final prompt = (income != null && expense != null)
        ? 'Analyze this budget. Income: $income $cur, Expense: $expense $cur. '
            'Give a short summary and one actionable tip.'
        : 'Analyze my budget and give one actionable tip.';
    return getResponse(prompt, l10n: l10n);
  }

  Future<List<String>> getSuggestions() async {
    return const [
      'How is my spending this month?',
      'Show me budget breakdown',
      'Tips for saving money',
    ];
  }

  String _buildPrompt({
    required String query,
    String? financialContext,
  }) {
    final contextBlock =
        (financialContext == null || financialContext.trim().isEmpty)
            ? 'No app financial data context was provided.'
            : financialContext.trim();

    return '''
You are CashTrack's finance assistant.
Use the user's app data context below when answering.
If data is missing for a claim, clearly say it is unavailable instead of guessing.
Keep the answer practical and concise.

App Financial Context:
$contextBlock

User Question:
$query
''';
  }

  Future<String> _getResponseFromBackend({
    required String query,
    String? financialContext,
    AppL10n? l10n,
  }) async {
    final callable =
        FirebaseFunctions.instanceFor(region: _functionsRegion).httpsCallable(
      'generateAiResponse',
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 30),
      ),
    );

    final result = await callable.call({
      'query': query,
      'financialContext': financialContext ?? '',
    });

    final data = result.data;
    if (data is Map && data['text'] is String) {
      final text = (data['text'] as String).trim();
      if (text.isNotEmpty) return text;
    }

    return l10n?.t('ai_service_no_response') ?? 'No response from AI service.';
  }

  Future<String> _getResponseFromGemini({
    required String query,
    String? financialContext,
    AppL10n? l10n,
    required String apiKey,
  }) async {
    final prompt = _buildPrompt(
      query: query,
      financialContext: financialContext,
    );

    final response = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/$_defaultModel:generateContent?key=$apiKey',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
        },
      },
    );

    final data = response.data;
    final candidates = data is Map<String, dynamic> ? data['candidates'] : null;
    if (candidates is List && candidates.isNotEmpty) {
      final content = candidates.first['content'];
      final parts = content is Map ? content['parts'] : null;
      if (parts is List && parts.isNotEmpty) {
        final text = parts.first['text'];
        if (text is String && text.trim().isNotEmpty) {
          return text.trim();
        }
      }
    }

    return l10n?.t('ai_service_no_response') ?? 'No response from AI service.';
  }
}
