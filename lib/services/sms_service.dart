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
import 'auth_service.dart';
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

  /// Checks if Notification Listener permission is currently granted.
  static Future<bool> isPermissionGranted() async {
    if (kIsWeb) return false;
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

  // Track recently imported transactions for cross-app duplicate detection
  // Stores (amount, type, accountId, txnId, timestamp) of recently saved transactions
  final List<({
    int amount,
    TransactionType type,
    String accountId,
    String? txnId,
    DateTime time
  })> _recentImports = [];

  // Stream that fires whenever a transaction is auto-imported (silent/daily_summary)
  final StreamController<TransactionModel> _importController =
      StreamController<TransactionModel>.broadcast();
  Stream<TransactionModel> get onTransactionImported => _importController.stream;

  // ── Bangla digit conversion ────────────────────────────────────────────
  /// Convert Bangla digits (০-৯) to ASCII (0-9)
  static String _convertBanglaDigits(String input) {
    const banglaDigits = '০১২৩৪৫৬৭৮৯';
    return input.replaceAllMapped(
      RegExp('[০-৯]'),
      (m) => banglaDigits.indexOf(m[0]!).toString(),
    );
  }

  // ── Amount patterns ─────────────────────────────────────────────────────
  // Matches: BDT 1,500.00 | Tk. 500 | Tk500 | ৳1000 | Amount: 2000.50 | ২০.০০ টাকা
  static final _amountPatterns = [
    RegExp(
      r'(?:BDT|Tk\.?|৳|টাকা|Amount:?)\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ),
    // Taka amount at end: "1500 Tk" or "1500.00 BDT" or "২০.০০ টাকা"
    RegExp(
      r'([\d,]+(?:\.\d{1,2})?)\s*(?:BDT|Tk\.?|৳|টাকা)',
      caseSensitive: false,
    ),
  ];

  // ── Financial keywords ─────────────────────────────────────────────────
  final List<String> _financialKeywords = [
    // MFS provider names
    'bkash', 'nagad', 'rocket', 'upay', 'surecash', 'mcash', 'ok wallet',
    // Core transaction keywords (English)
    'bank', 'credited', 'debited', 'withdrawn', 'deposited',
    'transaction', 'payment', 'received', 'cashin', 'cashout',
    'cash in', 'cash out', 'send money', 'bill payment',
    'recharge', 'merchant', 'transfer',
    'credit card', 'money received',
    // Additional transaction types (English)
    'add money', 'pay bill', 'paid successfully', 'successfully paid', 'biller',
    'mobile recharge', 'qr payment', 'scan & pay', 'scan and pay',
    'salary', 'payroll', 'bonus', 'refund', 'cashback',
    'remittance', 'payout',
    'emi', 'loan', 'installment',
    'donation', 'zakat',
    'interest', 'profit',
    // Bangla keywords — Core
    'পেয়েছেন', 'পাঠিয়েছেন', 'জমা', 'খরচ', 'প্রদান',
    'ক্যাশ ইন', 'ক্যাশ আউট', 'রিচার্জ', 'বিল',
    'টাকা', 'ব্যালেন্স', 'সেন্ড মানি', 'সফল', 'পেমেন্ট',
    'মার্চেন্ট', 'রিসিভ', 'ট্রান্সফার',
    // Bangla keywords — Additional
    'অ্যাড মানি', 'পে বিল', 'মোবাইল রিচার্জ', 'কিউআর পেমেন্ট',
    'বেতন', 'বোনাস', 'রিফান্ড', 'ক্যাশব্যাক',
    'রেমিটেন্স', 'কিস্তি', 'মুনাফা', 'সুদ',
    'সফলভাবে', 'সম্পন্ন',
  ];

  // ── Financial app package names ────────────────────────────────────────
  static const _financialPackages = {
    // Primary MFS apps
    'com.bKash.customerapp',
    'com.konasl.nagad',                  // Nagad (original)
    'com.nagad',                         // Nagad (alternate)
    'com.konasl.nagadhat',               // Nagad Hat
    'bd.com.nagad',                      // Nagad (BD variant)
    'com.dbbl.mbs',                      // Rocket (Dutch-Bangla Bank)
    'bd.com.upay',
    'com.grameenphone.gp',              // GP (may send money notifications)
    // Additional MFS apps
    'com.progoti.surecash',              // SureCash
    'com.onebank.ok',                    // OK Wallet (ONE Bank)
    'com.southeastbank.telecash',        // TeleCash (Southeast Bank)
    'com.sslwireless.mcash',             // mCash (Islami Bank)
    // Default SMS apps (bank SMS arrives through these)
    'com.google.android.apps.messaging', // Google Messages
    'com.samsung.android.messaging',     // Samsung Messages
    'com.android.mms',                   // Default Android SMS
  };



  // ── Merchant → Category mapping ────────────────────────────────────────
  final Map<String, String> _merchantCategories = {
    // Food & Dining
    'restaurant': 'cat_food',
    'pizza': 'cat_food',
    'kfc': 'cat_food',
    'burger': 'cat_food',
    'cafe': 'cat_food',
    'foodpanda': 'cat_food',
    'pathao food': 'cat_food',
    'hungrynaki': 'cat_food',
    'shohoz food': 'cat_food',
    // Transport
    'uber': 'cat_transport',
    'pathao': 'cat_transport',
    'obhai': 'cat_transport',
    'shohoz': 'cat_transport',
    'bus': 'cat_transport',
    'train': 'cat_transport',
    // Shopping
    'daraz': 'cat_shopping',
    'amazon': 'cat_shopping',
    'shop': 'cat_shopping',
    'mall': 'cat_shopping',
    'store': 'cat_shopping',
    'evaly': 'cat_shopping',
    'pickaboo': 'cat_shopping',
    'startech': 'cat_shopping',
    // Grocery
    'chaldal': 'cat_grocery',
    'shwapno': 'cat_grocery',
    'meena bazar': 'cat_grocery',
    'agora': 'cat_grocery',
    'pandamart': 'cat_grocery',
    // Bills & Utilities
    'electricity': 'cat_bills',
    'desco': 'cat_bills',
    'dpdc': 'cat_bills',
    'nesco': 'cat_bills',
    'bpdb': 'cat_bills',
    'palli bidyut': 'cat_bills',
    'gas bill': 'cat_bills',
    'titas': 'cat_bills',
    'water bill': 'cat_bills',
    'wasa': 'cat_bills',
    'dwasa': 'cat_bills',
    // Internet
    'internet': 'cat_internet',
    'isp': 'cat_internet',
    'broadband': 'cat_internet',
    'link3': 'cat_internet',
    'amber it': 'cat_internet',
    'carnival': 'cat_internet',
    // Mobile
    'mobile recharge': 'cat_mobile',
    'recharge': 'cat_mobile',
    'top up': 'cat_mobile',
    'topup': 'cat_mobile',
    'grameenphone': 'cat_mobile',
    'robi': 'cat_mobile',
    'banglalink': 'cat_mobile',
    'airtel': 'cat_mobile',
    'teletalk': 'cat_mobile',
    // Entertainment
    'movie': 'cat_entertainment',
    'netflix': 'cat_entertainment',
    'spotify': 'cat_entertainment',
    'game': 'cat_entertainment',
    'hoichoi': 'cat_entertainment',
    'bongo': 'cat_entertainment',
    'youtube premium': 'cat_entertainment',
    // Health
    'hospital': 'cat_health',
    'doctor': 'cat_health',
    'medicine': 'cat_health',
    'pharmacy': 'cat_health',
    'lab': 'cat_health',
    // Education
    'university': 'cat_education',
    'school': 'cat_education',
    'course': 'cat_education',
    'book': 'cat_education',
    'tuition': 'cat_education',
    'coaching': 'cat_education',
    // Salary & Income keywords (for merchant-match fallback)
    'salary': 'cat_salary',
    'payroll': 'cat_salary',
    'bonus': 'cat_salary',
    // Donation
    'donation': 'cat_others',
    'zakat': 'cat_others',
    'sadaqah': 'cat_others',
  };

  /// Initialise the notification listener.
  Future<void> init() async {
    if (kIsWeb) return;
    
    // SMS/Notification listener is strictly for Android.
    // iOS doesn't allow reading other apps' notifications or SMS.
    if (defaultTargetPlatform != TargetPlatform.android) {
      AppLogger.i('SmsService: Auto-import is only supported on Android.');
      return;
    }

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


  /// Content-based cross-app duplicate detection.
  /// Checks if a similar transaction was imported within a window.
  bool _isContentDuplicate(int amount, TransactionType type, String accountId, String? txnId) {
    final now = DateTime.now();

    // Clean up old entries (keep them for up to 10 minutes to be safe)
    _recentImports.removeWhere((r) => now.difference(r.time) > const Duration(minutes: 10));

    // Check for duplicates
    for (final recent in _recentImports) {
      // 1. If we have a transaction ID match, it is 100% a duplicate
      if (txnId != null && recent.txnId != null && txnId.toLowerCase() == recent.txnId!.toLowerCase()) {
        return true;
      }

      // 2. If no txnId matched (or one was missing), check if:
      //    - Amount is the same
      //    - Type (income/expense) is the same
      //    - Account is the same
      //    - Time difference is less than 3 minutes (dupe window)
      if (recent.amount == amount &&
          recent.type == type &&
          recent.accountId == accountId &&
          now.difference(recent.time) < const Duration(minutes: 3)) {
        return true;
      }
    }
    return false;
  }

  /// Record a recently imported transaction for content-based dedup.
  void _recordImport(int amount, TransactionType type, String accountId, String? txnId) {
    _recentImports.add((
      amount: amount,
      type: type,
      accountId: accountId,
      txnId: txnId,
      time: DateTime.now(),
    ));
    // Keep list bounded
    if (_recentImports.length > 50) {
      _recentImports.removeRange(0, _recentImports.length - 50);
    }
  }

  /// Helper to extract TxnID or TrxID from transaction SMS body.
  static String? _extractTxnId(String body) {
    final match = RegExp(
      r'(?:TrxID|TxnID|TxnId|Transaction ID)[:\s]*([a-zA-Z0-9]+)',
      caseSensitive: false,
    ).firstMatch(body);
    return match?.group(1);
  }

  /// Handle an incoming notification.
  Future<void> _onNotificationReceived(ServiceNotificationEvent event) async {
    try {
      final packageName = event.packageName ?? '';
      final title = event.title ?? '';
      final content = event.content ?? '';
      final text = '$title $content';

      AppLogger.d('📩 SMS/Notif received: pkg=$packageName, '
          'title="$title", content="${content.length > 80 ? '${content.substring(0, 80)}…' : content}", '
          'hasRemoved=${event.hasRemoved}');

      // Skip removed/dismissed notifications only if content is empty
      // (they have nothing useful to parse). Non-empty removed events
      // must still be checked for financial content before discarding.
      if (event.hasRemoved == true && content.trim().isEmpty) {
        AppLogger.d('📩 Skipping removed notification with empty content');
        return;
      }

      // Only process financial notifications
      if (!_isFinancialNotification(packageName, text)) {
        AppLogger.d('📩 Not a financial notification, skipping');
        return;
      }

      // De-duplicate by notification key
      final notifKey = '${event.packageName}_${event.id}_${content.hashCode}';
      if (_processedNotifIds.contains(notifKey)) {
        AppLogger.d('📩 Duplicate notification (key=$notifKey), skipping');
        return;
      }

      // After confirming it is financial and not a dup, skip dismissed ones.
      // This way we process a notification that arrives dismissed (e.g.
      // getActiveNotifications snapshot) but discard a second removed event
      // for the same notification that has already been imported.
      if (event.hasRemoved == true) {
        // Mark as seen so we don't process again, but do NOT save to Hive
        // (it may legitimately reappear later and we should still import it).
        AppLogger.d('📩 Financial but removed — skipping save (will import via inbox scan if missed)');
        return;
      }

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

      final transaction =
          _parseNotificationToTransaction(packageName, title, content);
      if (transaction != null) {
        // ── FIX: Content-based cross-app duplicate check ──
        final txnId = _extractTxnId(text);
        if (_isContentDuplicate(
            transaction.amount, transaction.type, transaction.accountId, txnId)) {
          AppLogger.d('📩 Content-based duplicate detected '
              '(amount=${transaction.amount}), skipping');
          return;
        }

        AppLogger.d('📩 Parsed transaction: type=${transaction.type}, '
            'amount=${transaction.amount}, account=${transaction.accountId}');
        _recordImport(
            transaction.amount, transaction.type, transaction.accountId, txnId);
        _handleParsedTransaction(transaction, packageName);
      } else {
        AppLogger.d('📩 Failed to parse notification into transaction. '
            'Full text: "$text"');
      }
    } catch (e, stack) {
      AppLogger.e('Notification processing error: $e\n$stack');
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
    // ── MFS providers (check BEFORE generic bank keywords) ──
    if (lower.contains('bkash') || lower.contains('b-kash') ||
        lower.contains('16247')) {
      return 'acc_bkash';
    }
    if (lower.contains('nagad') || lower.contains('16167') ||
        lower.contains('konasl') || lower.contains('nagadhat')) {
      return 'acc_nagad';
    }
    if (lower.contains('rocket') ||
        lower.contains('dbbl') ||
        lower.contains('dutch-bangla') ||
        lower.contains('dutch bangla') ||
        lower.contains('16216')) {
      return 'acc_rocket';
    }
    if (lower.contains('upay') || lower.contains('16268')) return 'acc_upay';
    if (lower.contains('surecash') || lower.contains('16345')) {
      return 'acc_online';
    }
    if (lower.contains('mcash') || lower.contains('ok wallet') ||
        lower.contains('telecash')) {
      return 'acc_online';
    }
    // ── Fallbacks for SMS formats that do not explicitly contain provider name ──
    // 1. bKash SMS format fallback (bkash uniquely uses "TrxID", others use "TxnID")
    if (lower.contains('trxid')) {
      return 'acc_bkash';
    }
    // 2. Nagad SMS format fallback (Nagad uses "TxnID" + "Amount: Tk" or "Balance: Tk")
    if (_isNagadSmsFormat(lower)) {
      return 'acc_nagad';
    }
    // Bank notification (only if no MFS provider matched above)
    if (lower.contains('bank') ||
        lower.contains('credited') ||
        lower.contains('debited') ||
        lower.contains('salary') ||
        lower.contains('emi') ||
        lower.contains('interest')) {
      return 'acc_online';
    }
    return 'acc_online';
  }

  /// Detect Nagad's distinctive SMS format.
  /// Nagad SMS patterns:
  ///  - "TxnID:" combined with "Amount: Tk" or "Balance: Tk"
  ///  - "Uddokta:" (Nagad Cash In agent, unique Nagad term)
  /// This format is unique to Nagad and not used by bKash/Rocket.
  static bool _isNagadSmsFormat(String lowerBody) {
    // "Uddokta" is exclusively used by Nagad for Cash In agents
    if (lowerBody.contains('uddokta')) return true;
    // TxnID + Amount/Balance pattern (common to all Nagad SMS)
    return lowerBody.contains('txnid') &&
        (lowerBody.contains('amount: tk') ||
         lowerBody.contains('balance: tk'));
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
        lower.contains('add money') ||
        lower.contains('transferred from') ||
        lower.contains('transfer received') ||
        lower.contains('salary') ||
        lower.contains('payroll') ||
        lower.contains('bonus') ||
        lower.contains('refund') ||
        lower.contains('cashback') ||
        lower.contains('remittance') ||
        lower.contains('payout') ||
        lower.contains('interest credited') ||
        lower.contains('profit credited') ||
        // Bangla credit
        lower.contains('পেয়েছেন') ||
        lower.contains('জমা') ||
        lower.contains('ক্যাশ ইন') ||
        lower.contains('অ্যাড মানি') ||
        lower.contains('বেতন') ||
        lower.contains('বোনাস') ||
        lower.contains('রিফান্ড') ||
        lower.contains('ক্যাশব্যাক') ||
        lower.contains('রেমিটেন্স') ||
        lower.contains('মুনাফা');

    // ── Debit (expense) patterns ──
    bool isDebit = lower.contains('sent') ||
        lower.contains('debited') ||
        lower.contains('withdrawn') ||
        lower.contains('cash out') ||
        lower.contains('cashout') ||
        lower.contains('payment') ||
        lower.contains('bill payment') ||
        lower.contains('pay bill') ||
        lower.contains('paid successfully') ||
        lower.contains('successfully paid') ||
        lower.contains('biller') ||
        lower.contains('recharge') ||
        lower.contains('mobile recharge') ||
        lower.contains('merchant') ||
        lower.contains('send money') ||
        lower.contains('balance transfer') ||
        lower.contains('transferred to') ||
        lower.contains('transfer successful') ||
        lower.contains('qr payment') ||
        lower.contains('scan & pay') ||
        lower.contains('scan and pay') ||
        lower.contains('donation') ||
        lower.contains('zakat') ||
        lower.contains('emi') ||
        lower.contains('installment') ||
        // Bangla debit
        lower.contains('পাঠিয়েছেন') ||
        lower.contains('খরচ') ||
        lower.contains('প্রদান') ||
        lower.contains('ক্যাশ আউট') ||
        lower.contains('রিচার্জ') ||
        lower.contains('মোবাইল রিচার্জ') ||
        lower.contains('বিল') ||
        lower.contains('পে বিল') ||
        lower.contains('সেন্ড মানি') ||
        lower.contains('সফল') ||
        lower.contains('সফলভাবে') ||
        lower.contains('সম্পন্ন') ||
        lower.contains('পেমেন্ট') ||
        lower.contains('কিউআর পেমেন্ট') ||
        lower.contains('কিস্তি');

    // Determine specific transaction type for better categorization
    String txType = 'general';
    if (lower.contains('bill payment') || lower.contains('pay bill') ||
        lower.contains('paid successfully') ||
        lower.contains('successfully paid') || lower.contains('biller') ||
        lower.contains('বিল') || lower.contains('পে বিল')) {
      txType = 'bill';
    } else if (lower.contains('recharge') ||
        lower.contains('mobile recharge') ||
        lower.contains('top up') ||
        lower.contains('topup') ||
        lower.contains('রিচার্জ') ||
        lower.contains('মোবাইল রিচার্জ')) {
      txType = 'recharge';
    } else if (lower.contains('send money') ||
        lower.contains('sent to') ||
        lower.contains('balance transfer') ||
        lower.contains('transferred to') ||
        lower.contains('transfer successful') ||
        lower.contains('পাঠিয়েছেন') ||
        lower.contains('সেন্ড মানি')) {
      txType = 'send_money';
    } else if (lower.contains('money received') ||
        lower.contains('received') ||
        lower.contains('transferred from') ||
        lower.contains('transfer received') ||
        lower.contains('পেয়েছেন') ||
        lower.contains('রিসিভ')) {
      txType = 'receive_money';
    } else if (lower.contains('cash out') ||
        lower.contains('cashout') ||
        lower.contains('ক্যাশ আউট')) {
      txType = 'cash_out';
    } else if (lower.contains('cash in') ||
        lower.contains('cashin') ||
        lower.contains('ক্যাশ ইন')) {
      txType = 'cash_in';
    } else if (lower.contains('add money') ||
        lower.contains('অ্যাড মানি')) {
      txType = 'add_money';
    } else if (lower.contains('salary') ||
        lower.contains('payroll') ||
        lower.contains('বেতন')) {
      txType = 'salary';
    } else if (lower.contains('remittance') ||
        lower.contains('payout') ||
        lower.contains('রেমিটেন্স')) {
      txType = 'remittance';
    } else if (lower.contains('refund') ||
        lower.contains('cashback') ||
        lower.contains('রিফান্ড') ||
        lower.contains('ক্যাশব্যাক')) {
      txType = 'refund';
    } else if (lower.contains('bonus') ||
        lower.contains('বোনাস')) {
      txType = 'bonus';
    } else if (lower.contains('emi') ||
        lower.contains('installment') ||
        lower.contains('কিস্তি')) {
      txType = 'emi';
    } else if (lower.contains('donation') ||
        lower.contains('zakat') ||
        lower.contains('sadaqah')) {
      txType = 'donation';
    } else if (lower.contains('interest') ||
        lower.contains('profit') ||
        lower.contains('মুনাফা') ||
        lower.contains('সুদ')) {
      txType = 'interest';
    } else if (lower.contains('qr payment') ||
        lower.contains('scan & pay') ||
        lower.contains('scan and pay') ||
        lower.contains('কিউআর পেমেন্ট')) {
      txType = 'qr_payment';
    } else if (lower.contains('merchant') || lower.contains('payment') ||
        lower.contains('মার্চেন্ট')) {
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
      // Convert any Bangla digits to ASCII before processing
      final normalizedBody = _convertBanglaDigits(body);

      // Detect transaction type (use original body for keyword matching)
      final detection = _detectTransactionType(body);
      if (!detection.isCredit && !detection.isDebit) {
        AppLogger.d('📩 Parse: no credit/debit keywords found in: '
            '"${body.length > 100 ? '${body.substring(0, 100)}…' : body}"');
        return null;
      }

      // Resolve transaction type.
      // When both credit and debit keywords are present (e.g. "Payment received
      // successfully"), break the tie using the more specific txType signal:
      // debit-oriented types (bill, recharge, send_money, …) take priority over
      // the generic "received" keyword.
      const debitTypes = {
        'bill', 'recharge', 'send_money', 'cash_out',
        'emi', 'donation', 'qr_payment', 'merchant_payment',
      };
      final TransactionType type;
      if (detection.isCredit && detection.isDebit) {
        type = debitTypes.contains(detection.txType)
            ? TransactionType.expense
            : TransactionType.income;
        AppLogger.d('📩 Parse: both credit+debit signals — txType="${detection.txType}" '
            '→ resolved as ${type.name}');
      } else {
        type = detection.isCredit ? TransactionType.income : TransactionType.expense;
      }

      // Extract amount (use normalized body with ASCII digits)
      int? amount;
      for (final pattern in _amountPatterns) {
        final match = pattern.firstMatch(normalizedBody);
        if (match != null) {
          final amountStr = match.group(1)?.replaceAll(',', '');
          final parsedDouble = double.tryParse(amountStr ?? '');
          if (parsedDouble != null) {
            amount = (parsedDouble * 100).toInt();
            break;
          }
        }
      }
      if (amount == null) {
        AppLogger.d('📩 Parse: no amount found in: '
            '"${normalizedBody.length > 100 ? '${normalizedBody.substring(0, 100)}…' : normalizedBody}"');
        return null;
      }

      // Detect account and category
      final accountId = _detectMfsAccount(source, body);
      final categoryId = _determineSmartCategory(body, detection.txType, type,
          accountId: accountId);

      // Extract target phone number or name (from/to)
      String? fromTarget;
      String? toTarget;

      final fromMatch = RegExp(
        r'(?:from|Sender:?|Uddokta:?)\s*([a-zA-Z0-9\+\-\s]{3,25})',
        caseSensitive: false,
      ).firstMatch(body);
      if (fromMatch != null) {
        fromTarget = _cleanTarget(fromMatch.group(1));
      }

      // Match "to 'Merchant Name'" (Nagad quoted format) or unquoted names
      final quotedToMatch = RegExp(
        r"(?:to|Receiver:?|Recipient:?)\s+'([^']{3,50})'",
        caseSensitive: false,
      ).firstMatch(body);
      if (quotedToMatch != null) {
        toTarget = _cleanTarget(quotedToMatch.group(1));
      } else {
        final toMatch = RegExp(
          r'(?:to|Receiver:?|Recipient:?)\s+(?:Agent|Merchant)?\s*([a-zA-Z0-9\+\-\s]{3,25})',
          caseSensitive: false,
        ).firstMatch(body);
        if (toMatch != null) {
          toTarget = _cleanTarget(toMatch.group(1));
        }
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
      case 'add_money':
        return 'Add Money';
      case 'salary':
        return 'Salary';
      case 'remittance':
        return 'Remittance';
      case 'refund':
        return 'Refund';
      case 'bonus':
        return 'Bonus';
      case 'emi':
        return 'EMI';
      case 'donation':
        return 'Donation';
      case 'interest':
        return 'Interest';
      case 'qr_payment':
        return 'QR Payment';
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
      String body, String txType, TransactionType transactionType,
      {String accountId = 'acc_online'}) {
    final lowerBody = body.toLowerCase();

    // ── Type-specific categories ─────────────────────────────────────────
    switch (txType) {
      case 'bill':
        // Try to detect specific bill type
        if (lowerBody.contains('desco') ||
            lowerBody.contains('dpdc') ||
            lowerBody.contains('nesco') ||
            lowerBody.contains('bpdb') ||
            lowerBody.contains('palli bidyut') ||
            lowerBody.contains('electricity')) {
          return 'cat_bills';
        }
        if (lowerBody.contains('titas') || lowerBody.contains('gas')) {
          return 'cat_bills';
        }
        if (lowerBody.contains('wasa') ||
            lowerBody.contains('dwasa') ||
            lowerBody.contains('water')) {
          return 'cat_bills';
        }
        if (lowerBody.contains('internet') ||
            lowerBody.contains('isp') ||
            lowerBody.contains('broadband') ||
            lowerBody.contains('link3') ||
            lowerBody.contains('carnival')) {
          return 'cat_internet';
        }
        return 'cat_bills';

      case 'recharge':
        return 'cat_mobile';

      case 'cash_in':
      case 'receive_money':
      case 'add_money':
        return _mfsCategoryForAccount(accountId, fallback: 'cat_other_income');

      case 'salary':
        return 'cat_salary';

      case 'remittance':
        return _mfsCategoryForAccount(accountId, fallback: 'cat_other_income');

      case 'bonus':
        return 'cat_salary';

      case 'refund':
        return _mfsCategoryForAccount(accountId, fallback: 'cat_other_income');

      case 'interest':
        return 'cat_other_income';

      case 'cash_out':
      case 'send_money':
        return _mfsCategoryForAccount(accountId, fallback: 'cat_others');

      case 'emi':
        return 'cat_bills';

      case 'donation':
        return 'cat_others';

      case 'qr_payment':
      case 'merchant_payment':
        // Try merchant matching first
        for (var entry in _merchantCategories.entries) {
          if (lowerBody.contains(entry.key)) return entry.value;
        }
        // If no specific merchant, use MFS category
        return _mfsCategoryForAccount(accountId, fallback: 'cat_shopping');
    }

    // ── Fallback: merchant category matching ─────────────────────────────
    for (var entry in _merchantCategories.entries) {
      if (lowerBody.contains(entry.key)) return entry.value;
    }

    // Final fallback — use MFS-specific category if from MFS account
    return _mfsCategoryForAccount(
      accountId,
      fallback: transactionType == TransactionType.income
          ? 'cat_other_income'
          : 'cat_others',
    );
  }

  /// Map MFS account IDs to their dedicated category IDs.
  /// Falls back to [fallback] for non-MFS accounts (bank, credit card, etc.).
  String _mfsCategoryForAccount(String accountId, {required String fallback}) {
    switch (accountId) {
      case 'acc_bkash':
        return 'cat_bkash';
      case 'acc_nagad':
        return 'cat_nagad';
      case 'acc_rocket':
        return 'cat_rocket';
      case 'acc_upay':
        return 'cat_upay';
      default:
        return fallback;
    }
  }

  Future<void> _handleParsedTransaction(
      TransactionModel transaction, String source) async {
    try {
      if (!_transactionRepo.isInitialized) {
        await _transactionRepo.init();
      }

      // Ensure the transaction has the current user's ID so it appears
      // in the logged-in user's transaction list. Without this, the
      // transaction would be saved with userId: null and filtered out
      // by getAllTransactions() which checks t.userId == currentUserId.
      final userId = AuthService().currentUser?.uid;
      final txnWithUser = transaction.copyWith(userId: userId);
      AppLogger.d('📩 Saving auto-imported tx: id=${txnWithUser.id}, '
          'userId=$userId, amount=${txnWithUser.amount}');

      final mode = await _getSmsMode();
      AppLogger.d('📩 SMS import mode: $mode');
      switch (mode) {
        case 'silent':
          await _transactionRepo.addTransaction(txnWithUser);
          _importController.add(txnWithUser);
          AppLogger.d('📩 Auto-imported silently: ${txnWithUser.id}');
          break;
        case 'daily_summary':
          await _transactionRepo.addTransaction(txnWithUser);
          _importController.add(txnWithUser);
          await _updateDailySummary(txnWithUser);
          AppLogger.d('📩 Auto-imported with daily summary: ${txnWithUser.id}');
          break;
        case 'ask':
        default:
          _showConfirmationNotification(txnWithUser, source);
          AppLogger.d('📩 Showing confirmation notification for: ${txnWithUser.id}');
      }
    } catch (e, stack) {
      AppLogger.e('Import mode handling failed: $e\n$stack');
    }
  }

  Future<String> _getSmsMode() async {
    final box = await _getSettingsBox();
    return (box.get(_smsModeKey, defaultValue: 'daily_summary') as String?) ?? 'daily_summary';
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
              'amount': '$currency${(transaction.amount / 100).toStringAsFixed(0)}',
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
    int totalAmount;

    if (savedDayKey == todayKey) {
      count = (box.get(_dailySummaryCountKey, defaultValue: 0) as int) + 1;
      totalAmount = (box.get(_dailySummaryAmountKey, defaultValue: 0) as int) +
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
                'amount': '$currency${(totalAmount / 100).toStringAsFixed(0)}',
              },
            )
          : l10n.t(
              'sms_daily_summary_multiple',
              params: {
                'count': count.toString(),
                'amount': '$currency${(totalAmount / 100).toStringAsFixed(0)}',
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
