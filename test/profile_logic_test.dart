import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:cashtrack/data/models/transaction_model.dart';
import 'package:cashtrack/presentation/profile/profile_logic.dart';

TransactionModel _tx(TransactionType type, int amount, DateTime date,
        {bool deleted = false}) =>
    TransactionModel(
      id: '${type.name}-$amount-${date.toIso8601String()}',
      type: type,
      amount: amount,
      categoryId: 'c',
      accountId: 'a',
      date: date,
      isDeleted: deleted,
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_US');
    await initializeDateFormatting('bn');
    await initializeDateFormatting('bn_BD');
  });

  group('DOB storage', () {
    test('round-trips the canonical format regardless of default locale', () {
      final previous = Intl.defaultLocale;
      Intl.defaultLocale = 'bn_BD';
      try {
        final stored = formatDobForStorage(DateTime(1998, 3, 7));
        expect(stored, '07 Mar 1998');
        expect(parseStoredDob(stored), DateTime(1998, 3, 7));
      } finally {
        Intl.defaultLocale = previous;
      }
    });

    test('accepts ISO strings and rejects garbage', () {
      expect(parseStoredDob('1998-03-07'), DateTime(1998, 3, 7));
      expect(parseStoredDob(''), isNull);
      expect(parseStoredDob('not a date'), isNull);
    });

    test('reads legacy values written with the Bangla locale', () {
      final legacy =
          DateFormat('dd MMM yyyy', 'bn_BD').format(DateTime(1998, 3, 7));
      expect(parseStoredDob(legacy), DateTime(1998, 3, 7));
    });

    test('display falls back to the raw value when unparseable', () {
      expect(displayDob('sometime', 'en'), 'sometime');
    });
  });

  group('profileInitials', () {
    test('handles empty, single and multi-part names', () {
      expect(profileInitials('   ', '?'), '?');
      expect(profileInitials('zahid', '?'), 'Z');
      expect(profileInitials('Zahid  Hasan Khan', '?'), 'ZK');
    });

    test('does not split Bangla grapheme clusters', () {
      // 'কি' is a consonant + vowel sign; it must stay one character.
      expect(profileInitials('কিবরিয়া', '?'), 'কি');
    });
  });

  test('normalizePhone strips common separators', () {
    expect(normalizePhone('+880 1712-345 678'), '+8801712345678');
    expect(normalizePhone('(017) 12345678'), '01712345678');
  });

  group('hasSavingsMonth', () {
    final jan = DateTime(2026, 1, 10);
    final feb = DateTime(2026, 2, 10);

    test('true when a month saves exactly 20%', () {
      expect(
        hasSavingsMonth([
          _tx(TransactionType.income, 100000, jan),
          _tx(TransactionType.expense, 80000, jan),
        ]),
        isTrue,
      );
    });

    test('false just under 20% and when there is no income', () {
      expect(
        hasSavingsMonth([
          _tx(TransactionType.income, 100000, jan),
          _tx(TransactionType.expense, 80001, jan),
          _tx(TransactionType.expense, 5000, feb),
        ]),
        isFalse,
      );
      expect(hasSavingsMonth(const []), isFalse);
    });

    test('months are evaluated independently', () {
      expect(
        hasSavingsMonth([
          _tx(TransactionType.income, 100000, jan),
          _tx(TransactionType.expense, 100000, jan),
          _tx(TransactionType.expense, 100000, feb), // Feb has no income
        ]),
        isFalse,
      );
    });

    test('ignores transfers and deleted transactions', () {
      expect(
        hasSavingsMonth([
          _tx(TransactionType.income, 100000, jan),
          _tx(TransactionType.expense, 90000, jan),
          _tx(TransactionType.expense, 90000, jan, deleted: true),
          _tx(TransactionType.transfer, 50000, jan),
        ]),
        isFalse,
      );
      expect(
        hasSavingsMonth([
          _tx(TransactionType.income, 100000, jan),
          _tx(TransactionType.expense, 90000, jan, deleted: true),
        ]),
        isTrue,
      );
    });
  });
}
