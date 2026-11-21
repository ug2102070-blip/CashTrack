// lib/services/recurring_transaction_service.dart
import 'dart:async';
import 'dart:ui' show Locale;
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../core/l10n/app_l10n.dart';
import '../core/utils/logger.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/transaction_repository.dart';
import 'notification_service.dart';

/// RecurringTransactionService automatically checks and posts due recurring transactions
/// (daily, weekly, monthly, yearly) into the ledger without manual re-entry.
class RecurringTransactionService {
  RecurringTransactionService._internal();
  static final RecurringTransactionService _instance =
      RecurringTransactionService._internal();
  factory RecurringTransactionService() => _instance;

  final TransactionRepository _txRepo = TransactionRepository();
  final AccountRepository _accountRepo = AccountRepository();
  final NotificationService _notifService = NotificationService();
  final Uuid _uuid = const Uuid();

  static const String _settingsBoxName = 'settingsBox';
  static const String _logPrefix = 'recurring_processed_';
  static const int _maxCatchupIterations = 12; // Cap missed cycles to prevent runaway backfills

  /// Runs the scheduled recurring checks and returns the number of newly posted transactions.
  Future<int> processDueTransactions() async {
    try {
      await _txRepo.init();
      await _accountRepo.init();

      final box = Hive.isBoxOpen(_settingsBoxName)
          ? Hive.box(_settingsBoxName)
          : await Hive.openBox(_settingsBoxName);

      final allTx = _txRepo.getAllTransactions();
      final recurringTemplates = allTx.where(
        (t) => t.isRecurring && t.recurringType != null && !t.isDeleted,
      ).toList();

      if (recurringTemplates.isEmpty) return 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      int postedCount = 0;

      for (final template in recurringTemplates) {
        final recurrence = template.recurringType!;
        DateTime nextDueDate = _getNextDueDate(template.date, recurrence);
        int catchupCount = 0;

        while (!nextDueDate.isAfter(today) && catchupCount < _maxCatchupIterations) {
          final dateKey = DateFormat('yyyy-MM-dd').format(nextDueDate);
          final logKey = '$_logPrefix${template.id}_$dateKey';

          final alreadyPosted = box.get(logKey, defaultValue: false) as bool;
          if (!alreadyPosted) {
            // Create a non-recurring occurrence transaction
            final newTx = TransactionModel(
              id: _uuid.v4(),
              type: template.type,
              amount: template.amount,
              categoryId: template.categoryId,
              accountId: template.accountId,
              date: nextDueDate,
              note: template.note != null && template.note!.isNotEmpty
                  ? '${template.note} (Auto: ${recurrence.name})'
                  : 'Auto: ${recurrence.name}',
              isRecurring: false,
              toAccountId: template.toAccountId,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              userId: template.userId,
            );

            await _txRepo.addTransaction(newTx);
            await _updateAccountBalance(newTx);

            // Mark this specific occurrence as posted to guarantee idempotency
            await box.put(logKey, true);
            postedCount++;
            AppLogger.i('Auto-posted recurring transaction: ${newTx.id} on $dateKey');
          }

          nextDueDate = _getNextDueDate(nextDueDate, recurrence);
          catchupCount++;
        }
      }

      if (postedCount > 0) {
        await _notifyUser(postedCount, box);
      }

      return postedCount;
    } catch (e, stack) {
      AppLogger.e('Failed to process recurring transactions: $e\n$stack');
      return 0;
    }
  }

  /// Calculates the next occurrence date based on the recurrence interval
  DateTime _getNextDueDate(DateTime from, RecurringType type) {
    switch (type) {
      case RecurringType.daily:
        return from.add(const Duration(days: 1));
      case RecurringType.weekly:
        return from.add(const Duration(days: 7));
      case RecurringType.monthly:
        // Safe month advancement handling varying month lengths
        final nextMonth = from.month == 12 ? 1 : from.month + 1;
        final nextYear = from.month == 12 ? from.year + 1 : from.year;
        final maxDaysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        final day = from.day > maxDaysInNextMonth ? maxDaysInNextMonth : from.day;
        return DateTime(nextYear, nextMonth, day, from.hour, from.minute);
      case RecurringType.yearly:
        final nextYear = from.year + 1;
        final isLeapFromFeb29 = from.month == 2 && from.day == 29;
        final day = isLeapFromFeb29 ? 28 : from.day;
        return DateTime(nextYear, from.month, day, from.hour, from.minute);
    }
  }

  /// Updates the relevant account balance(s)
  Future<void> _updateAccountBalance(TransactionModel tx) async {
    final account = _accountRepo.getAccountById(tx.accountId);
    if (account != null) {
      int delta = 0;
      if (tx.type == TransactionType.income) {
        delta = tx.amount;
      } else if (tx.type == TransactionType.expense) {
        delta = -tx.amount;
      } else if (tx.type == TransactionType.transfer) {
        delta = -tx.amount;
        if (tx.toAccountId != null) {
          final toAccount = _accountRepo.getAccountById(tx.toAccountId!);
          if (toAccount != null) {
            await _accountRepo.updateAccount(
              toAccount.copyWith(
                balance: toAccount.balance + tx.amount,
                updatedAt: DateTime.now(),
              ),
            );
          }
        }
      }

      if (delta != 0) {
        await _accountRepo.updateAccount(
          account.copyWith(
            balance: account.balance + delta,
            updatedAt: DateTime.now(),
          ),
        );
      }
    }
  }

  /// Sends a local notification to inform user that their scheduled transactions were logged
  Future<void> _notifyUser(int count, Box<dynamic> box) async {
    try {
      final lang = (box.get('language') as String?) ?? 'bn';
      final l10n = AppL10n(Locale(lang));
      final title = l10n.t('recurring_processed_title');
      final body = l10n.t(
        'recurring_processed_body',
        params: {'count': count.toString()},
      );

      await _notifService.showNotification(
        title: title,
        body: body,
      );
    } catch (e) {
      AppLogger.w('Failed to show recurring notification: $e');
    }
  }
}
