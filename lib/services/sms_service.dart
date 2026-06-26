// lib/services/sms_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui';


import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:uuid/uuid.dart';
import '../core/l10n/app_l10n.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/transaction_repository.dart';
import 'notification_service.dart';
import '../core/utils/logger.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  /// Requests Notification Listener permission (opens system settings).
  /// Returns true if permission is already granted.
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final isGranted = await NotificationListenerService.isPermissionGranted();
    if (isGranted) return true;
    // Opens the Notification Access settings page
    await NotificationListenerService.requestPermission();
    // Re-check after the user returns
    return NotificationListenerService.isPermissionGranted();
  }

  final TransactionRepository _transactionRepo = TransactionRepository();
  final NotificationService _notificationService = NotificationService();
  final Uuid _uuid = const Uuid();
  static const String _settingsBoxName = 'settingsBox';
  static const String _smsModeKey = 'smsMode';
  static const String _currencyKey = 'currency';
  static const String _dailySummaryDateKey = 'sms_daily_summary_date';
  static const String _dailySummaryCountKey = 'sms_daily_summary_count';
  static const String _dailySummaryAmountKey = 'sms_daily_summary_amount';
  static const String _dailySummaryNotifiedDateKey =
      'sms_daily_summary_notified_date';
  static const int _dailySummaryNotifyHour = 21;

  final Set<String> _processedNotifIds = {};
  StreamSubscription<ServiceNotificationEvent>? _notifSubscription;

  // Stream that fires whenever a transaction is auto-imported (silent/daily_summary)
  final StreamController<TransactionModel> _importController =
      StreamController<TransactionModel>.broadcast();
  Stream<TransactionModel> get onTransactionImported => _importController.stream;

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
    'credit card',
    // Bangla keywords
    'পেয়েছেন', 'পাঠিয়েছেন', 'জমা', 'খরচ', 'প্রদান',
    'ক্যাশ ইন', 'ক্যাশ আউট', 'রিচার্জ', 'বিল',
  ];

  // ── Financial app package names ────────────────────────────────────────
  static const _financialPackages = {
    'com.bKash.customerapp',
    'com.konasl.nagad',
    'com.dbbl.mbs', // Rocket
    'bd.com.upay',
    'com.grameenphone.gp', // GP may send money notifications
  };

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

  /// Initialise the notification listener.
  Future<void> init() async {
    if (kIsWeb) return;
    
    final box = await _getSettingsBox();
    final isTrackEnabled = box.get('smsTrack', defaultValue: false) == true;
    final hasPermission =
        await NotificationListenerService.isPermissionGranted();

    if (isTrackEnabled && hasPermission) {
      await _transactionRepo.init();
      
      // Load processed notification IDs from Hive settings box
      final savedIds = box.get('processedNotifIds', defaultValue: <dynamic>[]) as List<dynamic>;
      _processedNotifIds.clear();
      _processedNotifIds.addAll(savedIds.cast<String>());

      _startListening();
      
      // Query currently active notifications in the drawer
      await checkActiveNotifications();
    } else {
      stopListening();
    }
  }

  /// Query the currently active notifications in the notification drawer and process them.
  Future<void> checkActiveNotifications() async {
    if (kIsWeb) return;
    
    final box = await _getSettingsBox();
    final isTrackEnabled = box.get('smsTrack', defaultValue: false) == true;
    final hasPermission =
        await NotificationListenerService.isPermissionGranted();

    if (!isTrackEnabled || !hasPermission) return;

    try {
      final activeNotifications =
          await NotificationListenerService.getActiveNotifications();
      for (final event in activeNotifications) {
        await _onNotificationReceived(event);
      }
    } catch (e) {
      AppLogger.e('Error checking active notifications: $e');
    }
  }

  /// Start listening to notifications.
  void _startListening() {
    _notifSubscription?.cancel();
    _notifSubscription = NotificationListenerService.notificationsStream.listen(
      _onNotificationReceived,
      onError: (e) => AppLogger.e('Notification listener error: $e'),
    );
    AppLogger.d('Notification listener started');
  }

  /// Stop listening (call when feature is disabled).
  void stopListening() {
    _notifSubscription?.cancel();
    _notifSubscription = null;
  }

  /// Handle an incoming notification.
  Future<void> _onNotificationReceived(ServiceNotificationEvent event) async {
    try {
      final packageName = event.packageName ?? '';
      final title = event.title ?? '';
      final content = event.content ?? '';
      final text = '$title $content';

      // Only process financial notifications
      if (!_isFinancialNotification(packageName, text)) return;

      // De-duplicate by notification key
      final notifKey = '${event.packageName}_${event.id}_${content.hashCode}';
      if (_processedNotifIds.contains(notifKey)) return;
      
      _processedNotifIds.add(notifKey);

      // Save processed keys back to Hive settings box
      final box = await _getSettingsBox();
      final list = _processedNotifIds.toList();
      if (list.length > 200) {
        final trimmedList = list.sublist(list.length - 200);
        _processedNotifIds.clear();
        _processedNotifIds.addAll(trimmedList);
        await box.put('processedNotifIds', trimmedList);
      } else {
        await box.put('processedNotifIds', list);
      }

      // Ignore removed/dismissed notifications
      if (event.hasRemoved == true) return;

      final transaction =
          _parseNotificationToTransaction(packageName, title, content);
      if (transaction != null) {
        _handleParsedTransaction(transaction, packageName);
      }
    } catch (e) {
      AppLogger.e('Notification processing error: $e');
    }
  }

  /// Parse a raw text body (used by manual paste / clipboard import).
  TransactionModel? parseFromText(String text) {
    if (!_isFinancialText(text)) return null;
    return _parseTextToTransaction(text, 'manual');
  }

  bool _isFinancialNotification(String packageName, String body) {
    // Check if from a known financial app
    if (_financialPackages.contains(packageName)) return true;
    // Otherwise check the text content for financial keywords
    return _isFinancialText(body);
  }

  bool _isFinancialText(String body) {
    final lowerBody = body.toLowerCase();
    if (_financialKeywords.any((keyword) => lowerBody.contains(keyword))) {
      return true;
    }
    return false;
  }

  // ── Detect which MFS account the notification belongs to ───────────────
  String _detectMfsAccount(String packageName, String body) {
    final lower = '${packageName.toLowerCase()} ${body.toLowerCase()}';
    if (lower.contains('credit card') || lower.contains('creditcard')) {
      return 'acc_credit_card';
    }
    if (lower.contains('bkash') || lower.contains('16247')) return 'acc_bkash';
    if (lower.contains('nagad') || lower.contains('16167')) return 'acc_nagad';
    if (lower.contains('rocket') ||
        lower.contains('dbbl') ||
        lower.contains('dutch-bangla') ||
        lower.contains('16216')) {
      return 'acc_rocket';
    }
    if (lower.contains('upay')) return 'acc_upay';
    // Bank notification
    if (lower.contains('bank') ||
        lower.contains('credited') ||
        lower.contains('debited')) {
      return 'acc_online';
    }
    return 'acc_online';
  }

  // ── Detect transaction type from notification body ─────────────────────
  ({bool isCredit, bool isDebit, String txType}) _detectTransactionType(
      String body) {
    final lower = body.toLowerCase();

    // ── Credit (income) patterns ──
    bool isCredit = lower.contains('received') ||
        lower.contains('credited') ||
        lower.contains('cash in') ||
        lower.contains('cashin') ||
        lower.contains('transferred from') ||
        lower.contains('transfer received') ||
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
        lower.contains('balance transfer') ||
        lower.contains('transferred to') ||
        lower.contains('transfer successful') ||
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
    } else if (lower.contains('recharge') ||
        lower.contains('top up') ||
        lower.contains('topup') ||
        lower.contains('রিচার্জ')) {
      txType = 'recharge';
    } else if (lower.contains('send money') ||
        lower.contains('sent to') ||
        lower.contains('balance transfer') ||
        lower.contains('transferred to') ||
        lower.contains('transfer successful') ||
        lower.contains('পাঠিয়েছেন')) {
      txType = 'send_money';
    } else if (lower.contains('received') ||
        lower.contains('transferred from') ||
        lower.contains('transfer received') ||
        lower.contains('পেয়েছেন')) {
      txType = 'receive_money';
    } else if (lower.contains('cash out') ||
        lower.contains('cashout') ||
        lower.contains('ক্যাশ আউট')) {
      txType = 'cash_out';
    } else if (lower.contains('cash in') ||
        lower.contains('cashin') ||
        lower.contains('ক্যাশ ইন')) {
      txType = 'cash_in';
    } else if (lower.contains('merchant') || lower.contains('payment')) {
      txType = 'merchant_payment';
    }

    return (isCredit: isCredit, isDebit: isDebit, txType: txType);
  }

  TransactionModel? _parseNotificationToTransaction(
      String packageName, String title, String content) {
    return _parseTextToTransaction('$title $content', packageName);
  }

  TransactionModel? _parseTextToTransaction(String body, String source) {
    try {
      // Detect transaction type
      final detection = _detectTransactionType(body);
      if (!detection.isCredit && !detection.isDebit) return null;

      final type =
          detection.isCredit ? TransactionType.income : TransactionType.expense;

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
      final accountId = _detectMfsAccount(source, body);
      final categoryId = _determineSmartCategory(body, detection.txType, type);

      // Extract target phone number or name (from/to)
      String? fromTarget;
      String? toTarget;

      final fromMatch = RegExp(
        r'(?:from|Sender:?)\s*([a-zA-Z0-9\+\-\s]{3,25})',
        caseSensitive: false,
      ).firstMatch(body);
      if (fromMatch != null) {
        fromTarget = _cleanTarget(fromMatch.group(1));
      }

      final toMatch = RegExp(
        r'(?:to|Receiver:?|Recipient:?)\s+(?:Agent|Merchant)?\s*([a-zA-Z0-9\+\-\s]{3,25})',
        caseSensitive: false,
      ).firstMatch(body);
      if (toMatch != null) {
        toTarget = _cleanTarget(toMatch.group(1));
      }

      // Build note
      final accountName = _accountLabel(accountId);
      final formattedType = _formatTxType(detection.txType);
      
      String note = 'Auto: $accountName $formattedType';
      if (fromTarget != null && fromTarget.isNotEmpty) {
        note += ' from $fromTarget';
      } else if (toTarget != null && toTarget.isNotEmpty) {
        if (detection.txType == 'cash_out') {
          note += ' to Agent $toTarget';
        } else if (detection.txType == 'merchant_payment') {
          note += ' to Merchant $toTarget';
        } else {
          note += ' to $toTarget';
        }
      }

      return TransactionModel(
        id: _uuid.v4(),
        type: type,
        amount: amount,
        categoryId: categoryId,
        accountId: accountId,
        date: DateTime.now(),
        note: note,
        isRecurring: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      AppLogger.e('Error parsing notification: $e');
      return null;
    }
  }

  String _cleanTarget(String? target) {
    if (target == null) return '';
    // Take everything before a period, comma, or newline
    String clean = target.split(RegExp(r'[\.\,\r\n]')).first;
    
    // Replace "successful" or "success" (case-insensitive)
    clean = clean.replaceAll(RegExp(r'\s+successful', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'\s+success', caseSensitive: false), '');
    
    // Remove common trailing words
    final stopWords = ['fee', 'txnid', 'trxid', 'balance', 'tk', 'ref', 'at'];
    for (final stopWord in stopWords) {
      final idx = clean.toLowerCase().indexOf(' $stopWord');
      if (idx != -1) {
        clean = clean.substring(0, idx);
      }
    }
    
    return clean.trim();
  }

  String _formatTxType(String txType) {
    switch (txType) {
      case 'bill':
        return 'Bill Payment';
      case 'recharge':
        return 'Mobile Recharge';
      case 'send_money':
        return 'Send Money';
      case 'receive_money':
        return 'Receive Money';
      case 'cash_out':
        return 'Cash Out';
      case 'cash_in':
        return 'Cash In';
      case 'merchant_payment':
        return 'Merchant Payment';
      default:
        return 'Transaction';
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
      case 'acc_credit_card':
        return 'Credit Card';
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
        if (lowerBody.contains('desco') ||
            lowerBody.contains('dpdc') ||
            lowerBody.contains('nesco') ||
            lowerBody.contains('electricity')) {
          return 'cat_bills';
        }
        if (lowerBody.contains('titas') || lowerBody.contains('gas')) {
          return 'cat_bills';
        }
        if (lowerBody.contains('wasa') || lowerBody.contains('water')) {
          return 'cat_bills';
        }
        if (lowerBody.contains('internet') ||
            lowerBody.contains('isp') ||
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

  Future<void> _handleParsedTransaction(
      TransactionModel transaction, String source) async {
    try {
      if (!_transactionRepo.isInitialized) {
        await _transactionRepo.init();
      }

      final mode = await _getSmsMode();
      switch (mode) {
        case 'silent':
          await _transactionRepo.addTransaction(transaction);
          _importController.add(transaction);
          AppLogger.d('Notification auto-imported silently: ${transaction.id}');
          break;
        case 'daily_summary':
          await _transactionRepo.addTransaction(transaction);
          _importController.add(transaction);
          await _updateDailySummary(transaction);
          break;
        case 'ask':
        default:
          _showConfirmationNotification(transaction, source);
      }
    } catch (e) {
      AppLogger.e('Import mode handling failed: $e');
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

  void _showConfirmationNotification(
      TransactionModel transaction, String source) {
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
          payload: 'sms_transaction_json:${jsonEncode(transaction.toJson())}',
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
      totalAmount = (box.get(_dailySummaryAmountKey, defaultValue: 0.0) as num)
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
    _processedNotifIds.remove(transactionId);
  }
}
