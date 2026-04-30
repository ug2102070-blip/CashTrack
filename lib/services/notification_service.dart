import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../core/l10n/app_l10n.dart';
import '../data/models/transaction_model.dart';
import '../data/models/budget_model.dart';
import '../data/models/category_model.dart';
// à¦¨à¦¿à¦šà§‡à¦° à¦‡à¦®à¦ªà§‹à¦°à§à¦Ÿà¦—à§à¦²à§‹ à¦¯à§‹à¦— à¦•à¦°à¦¾ à¦¹à§Ÿà§‡à¦›à§‡
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const String _settingsBoxName = 'settingsBox';
  static const int _dailyReminderId = 9101;
  static const int _weeklySummaryId = 9102;
  static const String _weeklySummaryTask = 'weeklySummary';
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // à¦Ÿà¦¾à¦‡à¦®à¦œà§‹à¦¨ à¦¡à§‡à¦Ÿà¦¾ à¦‡à¦¨à¦¿à¦¶à¦¿à§Ÿà¦¾à¦²à¦¾à¦‡à¦œ à¦•à¦°à¦¾ à¦¹à§Ÿà§‡à¦›à§‡
    tz.initializeTimeZones();
    try {
      // Default to Bangladesh locale for scheduled notifications
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
    } catch (_) {
      // Fallback to device locale if timezone not found
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _initWorkManager();

    final settingsBox = await _openSettingsBox();
    final notificationsEnabled =
        (settingsBox.get('notifications') as bool?) ?? true;
    final reminderTime = settingsBox.get('dailyReminderTime') as String?;
    if (notificationsEnabled && reminderTime != null) {
      final parts = reminderTime.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          await scheduleDailyReminder(TimeOfDay(hour: hour, minute: minute));
        }
      }
    }
    final weeklyReport = settingsBox.get('weeklyReport') as bool? ?? false;
    if (notificationsEnabled && weeklyReport) {
      await updateWeeklyReport(true);
    }
  }

  Future<void> _initWorkManager() async {
    try {
      await Workmanager().initialize(callbackDispatcher);
      await Workmanager().registerPeriodicTask(
        'daily_budget_check',
        'budgetCheck',
        frequency: const Duration(days: 1),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (e) {
      // WorkManager not available on this device/configuration
      debugPrint('WorkManager init skipped: $e');
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final settings = await _openSettingsBox();
    if (!_notificationsEnabled(settings)) return;
    final l10n = _l10nFromSettings(settings);
    final androidDetails = AndroidNotificationDetails(
      'cashtrack_channel',
      l10n.t('app_name'),
      channelDescription: l10n.t('notifications'),
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id: _nextId(),
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> scheduleBillReminder({
    required String billName,
    required DateTime dueDate,
    required double amount,
  }) async {
    final settings = await _openSettingsBox();
    if (!_notificationsEnabled(settings)) return;
    final l10n = _l10nFromSettings(settings);
    final currency = _currencyFromSettings(settings);
    // Schedule notification 3 days before due date
    final reminderDate = dueDate.subtract(const Duration(days: 3));
    await _notifications.zonedSchedule(
      id: billName.hashCode,
      title: l10n.t('bill_reminder_title'),
      body: l10n.t(
        'bill_reminder_body',
        params: {
          'name': billName,
          'amount': '$currency${amount.toStringAsFixed(0)}',
        },
      ),
      scheduledDate: _convertToTimeZone(reminderDate),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'bill_reminders',
          l10n.t('bill_reminders_channel'),
          channelDescription: l10n.t('bill_reminders_channel_desc'),
          importance: Importance.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> showBudgetAlert({
    required String category,
    required double spent,
    required double budget,
  }) async {
    final settings = await _openSettingsBox();
    if (!_notificationsEnabled(settings)) return;
    final l10n = _l10nFromSettings(settings);
    final currency = _currencyFromSettings(settings);
    final percentage = (spent / budget * 100).toStringAsFixed(0);
    await showNotification(
      title: l10n.t('budget_alert_title'),
      body: l10n.t(
        'budget_alert_body',
        params: {
          'percent': percentage,
          'category': category,
          'spent': '$currency${spent.toStringAsFixed(0)}',
          'budget': '$currency${budget.toStringAsFixed(0)}',
        },
      ),
    );
  }

  Future<void> showLowBalanceAlert({
    required String accountName,
    required double balance,
  }) async {
    final settings = await _openSettingsBox();
    if (!_notificationsEnabled(settings)) return;
    final l10n = _l10nFromSettings(settings);
    final currency = _currencyFromSettings(settings);
    await showNotification(
      title: l10n.t('low_balance_alert_title'),
      body: l10n.t(
        'low_balance_alert_body',
        params: {
          'account': accountName,
          'amount': '$currency${balance.toStringAsFixed(0)}',
        },
      ),
    );
  }

  Future<void> scheduleDebtReminder({
    required String debtId,
    required String personName,
    required DateTime dueDate,
    required double amount,
    required bool isBorrowed,
  }) async {
    final settings = await _openSettingsBox();
    if (!_notificationsEnabled(settings)) return;
    final l10n = _l10nFromSettings(settings);
    final currency = _currencyFromSettings(settings);
    final now = DateTime.now();
    if (dueDate.isBefore(now)) return;

    final title = isBorrowed
        ? l10n.t('debt_payment_due_title')
        : l10n.t('debt_collection_due_title');
    final action = isBorrowed
        ? l10n.t('debt_payment_action_pay')
        : l10n.t('debt_payment_action_collect');
    final body = l10n.t(
      'debt_reminder_body',
      params: {
        'action': action,
        'amount': '$currency${amount.toStringAsFixed(0)}',
        'name': personName,
      },
    );

    final dayBefore = dueDate.subtract(const Duration(days: 1));
    if (dayBefore.isAfter(now)) {
      await _notifications.zonedSchedule(
        id: _debtId(debtId, 0),
        title: title,
        body: l10n.t('debt_due_tomorrow', params: {'body': body}),
        scheduledDate: _convertToTimeZone(dayBefore),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'debt_reminders',
            l10n.t('debt_reminders_channel'),
            channelDescription: l10n.t('debt_reminders_channel_desc'),
            importance: Importance.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    await _notifications.zonedSchedule(
      id: _debtId(debtId, 1),
      title: title,
      body: l10n.t('debt_due_today', params: {'body': body}),
      scheduledDate: _convertToTimeZone(dueDate),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'debt_reminders',
          l10n.t('debt_reminders_channel'),
          channelDescription: l10n.t('debt_reminders_channel_desc'),
          importance: Importance.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelDebtReminder(String debtId) async {
    await _notifications.cancel(id: _debtId(debtId, 0));
    await _notifications.cancel(id: _debtId(debtId, 1));
  }

  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    final settings = await _openSettingsBox();
    if (!_notificationsEnabled(settings)) return;
    final l10n = _l10nFromSettings(settings);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _notifications.zonedSchedule(
      id: _dailyReminderId,
      title: l10n.t('daily_reminder_title'),
      body: l10n.t('daily_reminder_body'),
      scheduledDate: scheduled,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          l10n.t('daily_reminder_channel'),
          channelDescription: l10n.t('daily_reminder_channel_desc'),
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(id: _dailyReminderId);
  }

  Future<void> updateWeeklyReport(bool enabled) async {
    if (!enabled) {
      await Workmanager().cancelByUniqueName(_weeklySummaryTask);
      await _notifications.cancel(id: _weeklySummaryId);
      return;
    }
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day, 9);
    final initialDelay = next.isAfter(now)
        ? next.difference(now)
        : next.add(const Duration(days: 1)).difference(now);
    await Workmanager().registerPeriodicTask(
      _weeklySummaryTask,
      _weeklySummaryTask,
      frequency: const Duration(days: 7),
      initialDelay: initialDelay,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (!enabled) {
      await _notifications.cancelAll();
      await Workmanager().cancelByUniqueName(_weeklySummaryTask);
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
  }

  int _nextId() {
    // Unique-ish per app session, avoids 0-999 collisions
    return DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
  }

  int _debtId(String debtId, int offset) {
    final base = debtId.hashCode & 0x7fffffff;
    return base + offset;
  }

  Future<Box<dynamic>> _openSettingsBox() async {
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
    final rawCurrency = settings.get('currency') as String?;
    if (rawCurrency == null || rawCurrency.isEmpty || rawCurrency == '?') {
      return '\u09F3';
    }
    if (rawCurrency == 'à§³') {
      return '\u09F3';
    }
    return rawCurrency;
  }

  bool _notificationsEnabled(Box<dynamic> settings) {
    return (settings.get('notifications') as bool?) ?? true;
  }

  // à¦à¦–à¦¾à¦¨à§‡ TZDateTime à¦à¦¬à¦‚ local à¦ à¦¿à¦• à¦•à¦°à¦¾ à¦¹à§Ÿà§‡à¦›à§‡
  tz.TZDateTime _convertToTimeZone(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    switch (task) {
      case 'budgetCheck':
        await _checkBudgetStatus();
        break;
      case NotificationService._weeklySummaryTask:
        await _sendWeeklySummary();
        break;
    }
    return Future.value(true);
  });
}

Future<void> _checkBudgetStatus() async {
  // Background-safe Hive + notifications setup
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(RecurringTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(BudgetModelAdapter());
  }

  final budgetsBox = await Hive.openBox('budgets');
  final txBox = await Hive.openBox('transactions');
  final categoriesBox = await Hive.openBox('categories');
  final Map<String, String> categoryNames = {};
  for (final raw in categoriesBox.values) {
    final c = raw is CategoryModel
        ? raw
        : CategoryModel.fromJson(Map<String, dynamic>.from(raw as Map));
    categoryNames[c.id] = c.name;
  }

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);

  final budgets = budgetsBox.values
      .map((raw) => raw is BudgetModel
          ? raw
          : BudgetModel.fromJson(Map<String, dynamic>.from(raw as Map)))
      .where((b) =>
          b.month.year == startOfMonth.year &&
          b.month.month == startOfMonth.month);

  final expenses = txBox.values
      .map((raw) => raw is TransactionModel
          ? raw
          : TransactionModel.fromJson(Map<String, dynamic>.from(raw as Map)))
      .where((t) =>
          !t.isDeleted &&
          t.type == TransactionType.expense &&
          t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          t.date.isBefore(endOfMonth.add(const Duration(days: 1))));

  final Map<String, double> spentByCategory = {};
  for (final t in expenses) {
    spentByCategory[t.categoryId] =
        (spentByCategory[t.categoryId] ?? 0) + t.amount;
  }

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await notifications.initialize(settings: settings);

  final settingsBox = await Hive.openBox('settingsBox');
  final notificationsEnabled =
      (settingsBox.get('notifications') as bool?) ?? true;
  final budgetAlertsEnabled =
      (settingsBox.get('budgetAlerts') as bool?) ?? true;
  if (!notificationsEnabled || !budgetAlertsEnabled) return;
  final l10n = AppL10n((settingsBox.get('language') as String?) == 'bn'
      ? const Locale('bn', 'BD')
      : const Locale('en'));
  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      'budget_alerts',
      l10n.t('budget_alerts_channel'),
      channelDescription: l10n.t('budget_alerts_channel_desc'),
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  for (final budget in budgets) {
    final spent = spentByCategory[budget.categoryId] ?? 0;
    if (budget.amount <= 0) continue;
    final percentage = spent / budget.amount;

    if (percentage >= 0.9) {
      final percentInt = (percentage * 100).toStringAsFixed(0);
      await notifications.show(
        id: DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
        title: l10n.t('budget_alert_title'),
        body: l10n.t(
          'budget_alert_body',
          params: {
            'percent': percentInt,
            'category': categoryNames[budget.categoryId] ?? budget.categoryId,
            'spent':
                '${(settingsBox.get('currency') as String?) ?? '৳'}${spent.toStringAsFixed(0)}',
            'budget':
                '${(settingsBox.get('currency') as String?) ?? '৳'}${budget.amount.toStringAsFixed(0)}',
          },
        ),
        notificationDetails: details,
      );
    }
  }
}

Future<void> _sendWeeklySummary() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(RecurringTypeAdapter());
  }

  final settingsBox = await Hive.openBox('settingsBox');
  final notificationsEnabled =
      (settingsBox.get('notifications') as bool?) ?? true;
  if (!notificationsEnabled) return;

  final txBox = await Hive.openBox('transactions');
  final l10n = AppL10n((settingsBox.get('language') as String?) == 'bn'
      ? const Locale('bn', 'BD')
      : const Locale('en'));
  final currency = (settingsBox.get('currency') as String?) ?? '৳';

  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 7));
  double income = 0;
  double expense = 0;

  for (final raw in txBox.values) {
    final t = raw is TransactionModel
        ? raw
        : TransactionModel.fromJson(Map<String, dynamic>.from(raw as Map));
    if (t.isDeleted) continue;
    if (t.date.isBefore(start) || t.date.isAfter(now)) continue;
    if (t.type == TransactionType.income) {
      income += t.amount;
    } else if (t.type == TransactionType.expense) {
      expense += t.amount;
    }
  }

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await notifications.initialize(settings: settings);

  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      'weekly_reports',
      l10n.t('weekly_report_channel'),
      channelDescription: l10n.t('weekly_report_channel_desc'),
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  final body = (income == 0 && expense == 0)
      ? l10n.t('weekly_report_empty')
      : l10n.t(
          'weekly_report_body',
          params: {
            'income': '$currency${income.toStringAsFixed(0)}',
            'expense': '$currency${expense.toStringAsFixed(0)}',
          },
        );

  await notifications.show(
    id: NotificationService._weeklySummaryId,
    title: l10n.t('weekly_report_title'),
    body: body,
    notificationDetails: details,
  );
}
