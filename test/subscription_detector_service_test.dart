import 'package:flutter_test/flutter_test.dart';

import 'package:cashtrack/data/models/transaction_model.dart';
import 'package:cashtrack/services/subscription_detector_service.dart';

void main() {
  TransactionModel expense({
    required String id,
    required DateTime date,
    String note = 'Netflix',
    bool isRecurring = false,
    bool isDeleted = false,
  }) {
    return TransactionModel(
      id: id,
      type: TransactionType.expense,
      amount: 499,
      categoryId: 'subscriptions',
      accountId: 'bkash',
      date: date,
      note: note,
      isRecurring: isRecurring,
      isDeleted: isDeleted,
    );
  }

  test('detects monthly repeated expenses as a subscription', () {
    final result = SubscriptionDetectorService().detectSubscriptions([
      expense(id: 'jan', date: DateTime(2026, 1, 24)),
      expense(id: 'feb', date: DateTime(2026, 2, 24)),
      expense(id: 'mar', date: DateTime(2026, 3, 24)),
    ]);

    expect(result, hasLength(1));
    expect(result.single.merchantName, 'Netflix');
    expect(result.single.nextExpectedDate, DateTime(2026, 4, 24));
    expect(result.single.transactionIds, ['jan', 'feb', 'mar']);
  });

  test('ignores transactions already marked recurring or deleted', () {
    final result = SubscriptionDetectorService().detectSubscriptions([
      expense(id: 'jan', date: DateTime(2026, 1, 24)),
      expense(id: 'feb', date: DateTime(2026, 2, 24), isRecurring: true),
      expense(id: 'mar', date: DateTime(2026, 3, 24), isDeleted: true),
    ]);

    expect(result, isEmpty);
  });

  test('does not detect irregular expense spacing', () {
    final result = SubscriptionDetectorService().detectSubscriptions([
      expense(id: 'jan', date: DateTime(2026, 1, 1)),
      expense(id: 'feb', date: DateTime(2026, 2, 15)),
      expense(id: 'mar', date: DateTime(2026, 3, 24)),
    ]);

    expect(result, isEmpty);
  });
}
