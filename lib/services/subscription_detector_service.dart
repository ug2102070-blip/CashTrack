import '../data/models/detected_subscription_model.dart';
import '../data/models/transaction_model.dart';

class SubscriptionDetectorService {
  SubscriptionDetectorService._internal();
  static final SubscriptionDetectorService _instance =
      SubscriptionDetectorService._internal();
  factory SubscriptionDetectorService() => _instance;

  static const _monthlyToleranceDays = 3;

  List<DetectedSubscription> detectSubscriptions(
    List<TransactionModel> transactions,
  ) {
    final expenses = transactions
        .where((tx) =>
            tx.type == TransactionType.expense &&
            !tx.isDeleted &&
            !tx.isRecurring)
        .toList();

    final grouped = <String, List<TransactionModel>>{};
    for (final tx in expenses) {
      final merchant = _normalizeMerchant(tx);
      final key = '${tx.amount.toStringAsFixed(2)}|${tx.categoryId}|$merchant';
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final detected = <DetectedSubscription>[];

    for (final group in grouped.values) {
      if (group.length < 2) continue;
      final sorted = group.toList()..sort((a, b) => a.date.compareTo(b.date));
      final intervals = <int>[];
      for (var i = 1; i < sorted.length; i++) {
        intervals.add(sorted[i].date.difference(sorted[i - 1].date).inDays);
      }
      if (!_isMonthlyRecurring(intervals)) continue;

      final last = sorted.last;
      final next = _advanceMonth(last.date);
      detected.add(DetectedSubscription(
        merchantName: _displayName(sorted.first),
        amount: last.amount,
        frequency: 'Monthly',
        lastDate: last.date,
        nextExpectedDate: next,
        transactionIds: sorted.map((tx) => tx.id).toList(),
      ));
    }

    detected.sort((a, b) => a.nextExpectedDate.compareTo(b.nextExpectedDate));
    return detected;
  }

  bool _isMonthlyRecurring(List<int> intervals) {
    if (intervals.isEmpty) return false;
    return intervals.every((days) {
      return days >= 30 - _monthlyToleranceDays &&
          days <= 30 + _monthlyToleranceDays;
    });
  }

  String _normalizeMerchant(TransactionModel tx) {
    final note = tx.note?.toLowerCase() ?? '';
    if (note.isNotEmpty) {
      return note.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ').trim();
    }
    return tx.categoryId.toLowerCase();
  }

  String _displayName(TransactionModel tx) {
    if (tx.note != null && tx.note!.trim().isNotEmpty) {
      return tx.note!.trim();
    }
    return tx.categoryId;
  }

  DateTime _advanceMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    final day = date.day;
    final maxDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    final safeDay = day <= maxDay ? day : maxDay;
    return DateTime(nextMonth.year, nextMonth.month, safeDay);
  }
}
