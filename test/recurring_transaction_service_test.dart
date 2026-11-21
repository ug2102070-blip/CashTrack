import 'package:flutter_test/flutter_test.dart';
import 'package:cashtrack/data/models/transaction_model.dart';

void main() {
  group('Recurring Calculations & Date Rules', () {
    DateTime getNextDueDate(DateTime from, RecurringType type) {
      switch (type) {
        case RecurringType.daily:
          return from.add(const Duration(days: 1));
        case RecurringType.weekly:
          return from.add(const Duration(days: 7));
        case RecurringType.monthly:
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

    test('daily recurrence advances exactly 1 day', () {
      final start = DateTime(2026, 5, 10);
      final next = getNextDueDate(start, RecurringType.daily);
      expect(next, DateTime(2026, 5, 11));
    });

    test('weekly recurrence advances exactly 7 days', () {
      final start = DateTime(2026, 5, 10);
      final next = getNextDueDate(start, RecurringType.weekly);
      expect(next, DateTime(2026, 5, 17));
    });

    test('monthly recurrence preserves day on standard months', () {
      final start = DateTime(2026, 3, 15);
      final next = getNextDueDate(start, RecurringType.monthly);
      expect(next, DateTime(2026, 4, 15));
    });

    test('monthly recurrence adjusts for shorter target months (Jan 31 -> Feb 28)', () {
      final start = DateTime(2026, 1, 31);
      final next = getNextDueDate(start, RecurringType.monthly);
      expect(next, DateTime(2026, 2, 28)); // 2026 is non-leap
    });

    test('yearly recurrence handles leap year Feb 29 safely', () {
      final leapFeb29 = DateTime(2024, 2, 29);
      final nextYear = getNextDueDate(leapFeb29, RecurringType.yearly);
      expect(nextYear, DateTime(2025, 2, 28));
    });
  });
}
