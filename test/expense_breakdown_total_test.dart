import 'package:flutter_test/flutter_test.dart';
import 'package:cashtrack/data/models/transaction_model.dart';
import 'package:intl/intl.dart';

void main() {
  group('Expense Breakdown Total & Calculation Tests', () {
    Map<String, double> calculateCategoryData(
      List<TransactionModel> transactions,
      TransactionType type,
    ) {
      final Map<String, double> data = {};
      for (var t in transactions.where((t) => t.type == type)) {
        // Must convert Paisa to Taka (t.amount / 100.0)
        data[t.categoryId] = (data[t.categoryId] ?? 0) + (t.amount / 100.0);
      }
      final sorted = data.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return Map.fromEntries(sorted);
    }

    double getTotal(Map<String, double> data) =>
        data.values.fold(0, (s, a) => s + a);

    String formatAmount(double amount) {
      if (amount >= 1000000) {
        return '${(amount / 1000000).toStringAsFixed(1)}M';
      } else if (amount >= 100000) {
        return '${(amount / 1000).toStringAsFixed(0)}K';
      } else if (amount >= 10000) {
        return '${(amount / 1000).toStringAsFixed(1)}K';
      }
      return NumberFormat('#,##0').format(amount);
    }

    test('accurately calculates and formats total in Taka from Paisa', () {
      final transactions = [
        TransactionModel(
          id: '1',
          type: TransactionType.expense,
          amount: 50000, // 500 Taka in Paisa
          categoryId: 'food',
          accountId: 'cash',
          date: DateTime(2026, 11, 10),
        ),
        TransactionModel(
          id: '2',
          type: TransactionType.expense,
          amount: 100000, // 1000 Taka in Paisa
          categoryId: 'groceries',
          accountId: 'bkash',
          date: DateTime(2026, 11, 11),
        ),
        TransactionModel(
          id: '3',
          type: TransactionType.expense,
          amount: 150000, // 1500 Taka in Paisa
          categoryId: 'food',
          accountId: 'cash',
          date: DateTime(2026, 11, 12),
        ),
      ];

      final data = calculateCategoryData(transactions, TransactionType.expense);
      expect(data['food'], equals(2000.0)); // 500 + 1500
      expect(data['groceries'], equals(1000.0)); // 1000

      final totalTaka = getTotal(data);
      expect(totalTaka, equals(3000.0));
      expect(formatAmount(totalTaka), equals('3,000'));
    });

    test('formats large totals with K and M denominations accurately', () {
      expect(formatAmount(500.0), equals('500'));
      expect(formatAmount(2500.0), equals('2,500'));
      expect(formatAmount(25000.0), equals('25.0K'));
      expect(formatAmount(150000.0), equals('150K'));
      expect(formatAmount(2500000.0), equals('2.5M'));
    });
  });
}
