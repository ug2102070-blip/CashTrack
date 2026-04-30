// lib/services/sms_service.dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/l10n/app_l10n.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/transaction_repository.dart';
import 'notification_service.dart';
import '../core/utils/logger.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  static Future<bool> requestPermission() async {
    return SmsService()._requestPermissions();
  }

  final SmsQuery _smsQuery = SmsQuery();
  final TransactionRepository _transactionRepo = TransactionRepository();
  final NotificationService _notificationService = NotificationService();
  static const String _settingsBoxName = 'settingsBox';
  static const String _smsModeKey = 'smsMode';
  static const String _currencyKey = 'currency';
  static const String _dailySummaryDateKey = 'sms_daily_summary_date';
  static const String _dailySummaryCountKey = 'sms_daily_summary_count';
  static const String _dailySummaryAmountKey = 'sms_daily_summary_amount';
  static const String _dailySummaryNotifiedDateKey =
      'sms_daily_summary_notified_date';
  static const int _dailySummaryNotifyHour = 21;
  static const String _lastSmsIdKey = 'sms_last_processed_id';

  final Set<String> _processedSmsIds = {};

  // ── Amount patterns ─────────────────────────────────────────────────────
  // Matches: BDT 1,500.00 | Tk. 500 | Tk500 | ৳1000 | Amount: 2000.50
  static final _amountPatterns = [
    RegExp(
      r'(?:BDT|Tk\.?|৳|Amount:?)\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ),
    // Taka amount at end: "1500 Tk" or "1500.00 BDT"
    RegExp(
      r'([\d,]+(?:\.\d{1,2})?)\s*(?:BDT|Tk\.?|৳)',
      caseSensitive: false,
    ),
  ];

  // ── Financial keywords ─────────────────────────────────────────────────
  final List<String> _financialKeywords = [
    'bkash', 'nagad', 'rocket', 'upay',
    'bank', 'credited', 'debited', 'withdrawn', 'deposited',
    'transaction', 'payment', 'received', 'cashin', 'cashout',
    'cash in', 'cash out', 'send money', 'bill payment',
    'recharge', 'merchant', 'transfer',
    // Bangla keywords
    'পেয়েছেন', 'পাঠিয়েছেন', 'জমা', 'খরচ', 'প্রদান',
    'ক্যাশ ইন', 'ক্যাশ আউট', 'রিচার্জ', 'বিল',
  ];

  // ── Merchant → Category mapping ────────────────────────────────────────
  final Map<String, String> _merchantCategories = {
    'restaurant': 'cat_food',
    'pizza': 'cat_food',
    'kfc': 'cat_food',
    'burger': 'cat_food',
    'cafe': 'cat_food',
    'foodpanda': 'cat_food',
    'pathao food': 'cat_food',
    'hungrynaki': 'cat_food',
    'uber': 'cat_transport',
    'pathao': 'cat_transport',
    'obhai': 'cat_transport',
    'shohoz': 'cat_transport',
    'bus': 'cat_transport',
    'train': 'cat_transport',
    'daraz': 'cat_shopping',
    'amazon': 'cat_shopping',
    'shop': 'cat_shopping',
    'mall': 'cat_shopping',
    'store': 'cat_shopping',
    'chaldal': 'cat_grocery',
    'shwapno': 'cat_grocery',
    'meena bazar': 'cat_grocery',
    'agora': 'cat_grocery',
    'electricity': 'cat_bills',
    'desco': 'cat_bills',
    'dpdc': 'cat_bills',
    'nesco': 'cat_bills',
    'gas bill': 'cat_bills',
    'titas': 'cat_bills',
    'water bill': 'cat_bills',
    'wasa': 'cat_bills',
    'internet': 'cat_internet',
    'isp': 'cat_internet',
    'broadband': 'cat_internet',
    'mobile recharge': 'cat_mobile',
    'recharge': 'cat_mobile',
    'top up': 'cat_mobile',
    'topup': 'cat_mobile',
    'grameenphone': 'cat_mobile',
    'robi': 'cat_mobile',
    'banglalink': 'cat_mobile',
    'airtel': 'cat_mobile',
    'teletalk': 'cat_mobile',
    'movie': 'cat_entertainment',
    'netflix': 'cat_entertainment',
    'spotify': 'cat_entertainment',
    'game': 'cat_entertainment',
    'hospital': 'cat_health',
    'doctor': 'cat_health',
    'medicine': 'cat_health',
    'pharmacy': 'cat_health',
    'university': 'cat_education',
    'school': 'cat_education',
    'course': 'cat_education',
    'book': 'cat_education',
    'tuition': 'cat_education',
  };

  Future<void> init() async {
    if (kIsWeb) return; // SMS not supported on web
    final hasPermission = await _requestPermissions();
    if (hasPermission) {
      await _transactionRepo.init();
      await _pollNewSms();
    }
  }

  Future<bool> _requestPermissions() async {
    if (kIsWeb) return false;
    final statuses = await [
      Permission.sms,
    ].request();
    return statuses[Permission.sms]?.isGranted ?? false;
  }

  /// Polls inbox for new SMS since last processed id.
  Future<void> _pollNewSms() async {
    try {
      final box = await _getSettingsBox();
      final lastId = (box.get(_lastSmsIdKey) as int?) ?? 0;

      final messages = await _smsQuery.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 50,
      );

      int latestId = lastId;
      for (final message in messages) {
        final id = message.id ?? 0;
        if (id <= lastId) continue;
        if (id > latestId) latestId = id;

        final idStr = id.toString();
        if (_processedSmsIds.contains(idStr)) continue;
        _processedSmsIds.add(idStr);

        if (_isFinancialSms(message.body ?? '')) {
          final transaction = _parseSmsToTransaction(message);
          if (transaction != null) {
            await _handleParsedTransaction(transaction, message.sender ?? '');
          }
        }
      }

      if (latestId > lastId) {
        await box.put(_lastSmsIdKey, latestId);
      }
    } catch (e) {
      AppLogger.e('SMS poll failed: $e');
    }
  }

  /// Call this from WorkManager periodic task to check new SMS in background.
  Future<void> checkNewSmsInBackground() async {
    if (kIsWeb) return;
    final hasPermission = await _requestPermissions();
    if (hasPermission) await _pollNewSms();
  }

  Future<void> _handleParsedTransaction(
      TransactionModel transaction, String sender) async {
    try {
      if (!_transactionRepo.isInitialized) {
        await _transactionRepo.init();
      }

      final mode = await _getSmsMode();
      switch (mode) {
        case 'silent':
          await _transactionRepo.addTransaction(transaction);
          AppLogger.d('SMS auto-imported silently: ${transaction.id}');
          break;
        case 'daily_summary':
          await _transactionRepo.addTransaction(transaction);
          await _updateDailySummary(transaction);
          break;
        case 'ask':
        default:
          _showConfirmationNotification(transaction, sender);
      }
    } catch (e) {
      AppLogger.e('SMS mode handling failed: $e');
    }
  }

  Future<String> _getSmsMode() async {
    final box = await _getSettingsBox();
    return (box.get(_smsModeKey, defaultValue: 'ask') as String?) ?? 'ask';
  }

  Future<Box> _getSettingsBox() async {
    if (Hive.isBoxOpen(_settingsBoxName)) {
      return Hive.box(_settingsBoxName);
    }
    return Hive.openBox(_settingsBoxName);
  }

  AppL10n _l10nFromSettings(Box<dynamic> settings) {
    final language = (settings.get('language') as String?) ?? 'en';
    final locale =
        language == 'bn' ? const Locale('bn', 'BD') : const Locale('en');
    return AppL10n(locale);
  }

  String _currencyFromSettings(Box<dynamic> settings) {
    return (settings.get(_currencyKey) as String?) ?? '৳';
  }

  bool _isFinancialSms(String body) {
    final lowerBody = body.toLowerCase();
    if (_financialKeywords.any((keyword) => lowerBody.contains(keyword))) {
      return true;
    }
    return false;
  }

  // ── Detect which MFS account the SMS belongs to ────────────────────────
  String _detectMfsAccount(String sender, String body) {
    final lower = '${sender.toLowerCase()} ${body.toLowerCase()}';
    if (lower.contains('bkash') || lower.contains('16247')) return 'acc_bkash';
    if (lower.contains('nagad') || lower.contains('16167')) return 'acc_nagad';
    if (lower.contains('rocket') || lower.contains('dbbl') ||
        lower.contains('dutch-bangla') || lower.contains('16216')) {
      return 'acc_rocket';
    }
    if (lower.contains('upay')) return 'acc_upay';
    // Bank SMS
    if (lower.contains('bank') || lower.contains('credited') ||
        lower.contains('debited')) {
      return 'acc_online';
    }
    return 'acc_online';
  }

  // ── Detect transaction type from SMS body ──────────────────────────────
  ({bool isCredit, bool isDebit, String txType}) _detectTransactionType(
      String body) {
    final lower = body.toLowerCase();

    // ── Credit (income) patterns ──
    bool isCredit = lower.contains('received') ||
        lower.contains('credited') ||
        lower.contains('cash in') ||
        lower.contains('cashin') ||
        lower.contains('পেয়েছেন') ||
        lower.contains('জমা') ||
        lower.contains('ক্যাশ ইন');

    // ── Debit (expense) patterns ──
    bool isDebit = lower.contains('sent') ||
        lower.contains('debited') ||
        lower.contains('withdrawn') ||
        lower.contains('cash out') ||
        lower.contains('cashout') ||
        lower.contains('payment') ||
        lower.contains('bill payment') ||
        lower.contains('recharge') ||
        lower.contains('merchant') ||
        lower.contains('send money') ||
        lower.contains('পাঠিয়েছেন') ||
        lower.contains('খরচ') ||
        lower.contains('প্রদান') ||
        lower.contains('ক্যাশ আউট') ||
        lower.contains('রিচার্জ') ||
        lower.contains('বিল');

    // Determine specific transaction type for better categorization
    String txType = 'general';
    if (lower.contains('bill payment') || lower.contains('বিল')) {
      txType = 'bill';
    } else if (lower.contains('recharge') || lower.contains('top up') ||
        lower.contains('topup') || lower.contains('রিচার্জ')) {
      txType = 'recharge';
    } else if (lower.contains('send money') || lower.contains('sent to') ||
        lower.contains('পাঠিয়েছেন')) {
      txType = 'send_money';
    } else if (lower.contains('received') || lower.contains('পেয়েছেন')) {
      txType = 'receive_money';
    } else if (lower.contains('cash out') || lower.contains('cashout') ||
        lower.contains('ক্যাশ আউট')) {
      txType = 'cash_out';
    } else if (lower.contains('cash in') || lower.contains('cashin') ||
        lower.contains('ক্যাশ ইন')) {
      txType = 'cash_in';
    } else if (lower.contains('merchant') || lower.contains('payment')) {
      txType = 'merchant_payment';
    }

    return (isCredit: isCredit, isDebit: isDebit, txType: txType);
  }

  TransactionModel? _parseSmsToTransaction(SmsMessage message) {
    try {
      final body = message.body ?? '';
      final sender = message.sender ?? '';

      // Detect transaction type
      final detection = _detectTransactionType(body);
      if (!detection.isCredit && !detection.isDebit) return null;

      final type = detection.isCredit
          ? TransactionType.income
          : TransactionType.expense;

      // Extract amount
      double? amount;
      for (final pattern in _amountPatterns) {
        final match = pattern.firstMatch(body);
        if (match != null) {
          final amountStr = match.group(1)?.replaceAll(',', '');
          amount = double.tryParse(amountStr ?? '');
          if (amount != null) break;
        }
      }
      if (amount == null) return null;

      // Detect account and category
      final accountId = _detectMfsAccount(sender, body);
      final categoryId = _determineSmartCategory(body, detection.txType, type);

      // Build note
      final accountName = _accountLabel(accountId);
      final note = 'Auto: $accountName ${detection.txType.replaceAll('_', ' ')} '
          '— from SMS (${sender.isNotEmpty ? sender : 'unknown'})';

      return TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        amount: amount,
        categoryId: categoryId,
        accountId: accountId,
        date: message.date ?? DateTime.now(),
        note: note,
        isRecurring: false,
        smsId: message.id?.toString(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      AppLogger.e('Error parsing SMS: $e');
      return null;
    }
  }

  String _accountLabel(String accountId) {
    switch (accountId) {
      case 'acc_bkash':
        return 'bKash';
      case 'acc_nagad':
        return 'Nagad';
      case 'acc_rocket':
        return 'Rocket';
      case 'acc_upay':
        return 'Upay';
      case 'acc_online':
        return 'Bank';
      default:
        return 'Other';
    }
  }

  String _determineSmartCategory(
      String body, String txType, TransactionType transactionType) {
    final lowerBody = body.toLowerCase();

    // ── Type-specific categories ─────────────────────────────────────────
    switch (txType) {
      case 'bill':
        // Try to detect specific bill type
        if (lowerBody.contains('desco') || lowerBody.contains('dpdc') ||
            lowerBody.contains('nesco') || lowerBody.contains('electricity')) {
          return 'cat_bills';
        }
        if (lowerBody.contains('titas') || lowerBody.contains('gas')) {
          return 'cat_bills';
        }
        if (lowerBody.contains('wasa') || lowerBody.contains('water')) {
          return 'cat_bills';
        }
        if (lowerBody.contains('internet') || lowerBody.contains('isp') ||
            lowerBody.contains('broadband')) {
          return 'cat_internet';
        }
        return 'cat_bills';

      case 'recharge':
        return 'cat_mobile';

      case 'cash_in':
      case 'receive_money':
        return 'cat_other_income';

      case 'cash_out':
        return 'cat_others';

      case 'send_money':
        return 'cat_others';

      case 'merchant_payment':
        // Try merchant matching
        for (var entry in _merchantCategories.entries) {
          if (lowerBody.contains(entry.key)) return entry.value;
        }
        return 'cat_shopping';
    }

    // ── Fallback: merchant category matching ─────────────────────────────
    for (var entry in _merchantCategories.entries) {
      if (lowerBody.contains(entry.key)) return entry.value;
    }

    // Final fallback
    return transactionType == TransactionType.income
        ? 'cat_other_income'
        : 'cat_others';
  }

  void _showConfirmationNotification(
      TransactionModel transaction, String sender) {
    if (!_transactionRepo.isInitialized) {
      AppLogger.w('Transaction repo not initialized; skipping save/notify');
      return;
    }

    final isIncome = transaction.type == TransactionType.income;
    try {
      _getSettingsBox().then((settings) {
        final l10n = _l10nFromSettings(settings);
        final currency = _currencyFromSettings(settings);
        final action = isIncome
            ? l10n.t('sms_action_received')
            : l10n.t('sms_action_spent');
        _notificationService.showNotification(
          title: l10n.t('sms_tx_detected_title'),
          body: l10n.t(
            'sms_tx_detected_body',
            params: {
              'action': action,
              'amount': '$currency${transaction.amount.toStringAsFixed(0)}',
            },
          ),
          payload: 'sms_transaction:${transaction.id}',
        );
      });
    } catch (e) {
      AppLogger.e('Notification failed: $e');
    }
  }

  Future<void> _updateDailySummary(TransactionModel transaction) async {
    final box = await _getSettingsBox();
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final savedDayKey =
        (box.get(_dailySummaryDateKey, defaultValue: '') as String?) ?? '';

    int count;
    double totalAmount;

    if (savedDayKey == todayKey) {
      count = (box.get(_dailySummaryCountKey, defaultValue: 0) as int) + 1;
      totalAmount =
          (box.get(_dailySummaryAmountKey, defaultValue: 0.0) as num)
                  .toDouble() +
              transaction.amount;
    } else {
      count = 1;
      totalAmount = transaction.amount;
    }

    await box.put(_dailySummaryDateKey, todayKey);
    await box.put(_dailySummaryCountKey, count);
    await box.put(_dailySummaryAmountKey, totalAmount);

    final notifiedDayKey =
        (box.get(_dailySummaryNotifiedDateKey, defaultValue: '') as String?) ??
            '';

    if (notifiedDayKey == todayKey || now.hour < _dailySummaryNotifyHour) {
      return;
    }

    await box.put(_dailySummaryNotifiedDateKey, todayKey);

    final currency = _currencyFromSettings(box);
    final l10n = _l10nFromSettings(box);
    final isSingle = count == 1;
    await _notificationService.showNotification(
      title: l10n.t('sms_daily_summary_title'),
      body: isSingle
          ? l10n.t(
              'sms_daily_summary_single',
              params: {
                'amount': '$currency${totalAmount.toStringAsFixed(0)}',
              },
            )
          : l10n.t(
              'sms_daily_summary_multi',
              params: {
                'count': count.toString(),
                'amount': '$currency${totalAmount.toStringAsFixed(0)}',
              },
            ),
      payload: 'sms_daily_summary:$todayKey',
    );
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> confirmAndSaveTransaction(TransactionModel transaction) async {
    await _transactionRepo.addTransaction(transaction);
  }

  void cancelTransaction(String transactionId) {
    AppLogger.d('Transaction cancelled: $transactionId');
    _processedSmsIds.remove(transactionId);
  }
}
