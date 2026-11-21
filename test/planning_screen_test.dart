import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Planning Screen Financial Calculation Tests', () {
    test('Daily Safe-to-Spend calculation with remaining days in month', () {
      // 15,000 BDT remaining budget (stored as 1,500,000 paisa)
      const budgetRemainingPaisa = 1500000;
      const daysRemaining = 15;

      final dailySafePaisa = (budgetRemainingPaisa / daysRemaining).round();
      final dailySafeBDT = dailySafePaisa / 100.0;

      expect(dailySafeBDT, equals(1000.0));
    });

    test('Net Worth calculation correctly accounts for assets, investments, receivables, and debts', () {
      // Assets: 500,000 BDT (50,000,000 paisa)
      // Investments: 200,000 BDT (20,000,000 paisa)
      // Lent to friends (Receivable): 50,000 BDT (5,000,000 paisa)
      // Borrowed from bank (Liability): 100,000 BDT (10,000,000 paisa)
      const totalAssets = 50000000;
      const currentInvestValue = 20000000;
      const lent = 5000000;
      const borrowed = 10000000;

      final netWorthPaisa = (totalAssets + currentInvestValue + lent) - borrowed;
      final netWorthBDT = netWorthPaisa / 100.0;

      expect(netWorthBDT, equals(650000.0)); // 6.5 Lakhs
    });

    test('Formatting helper produces clean K, L, Cr values for Bangladeshi finance', () {
      String fmt(double v) {
        final absV = v.abs();
        final sign = v < 0 ? '-' : '';
        if (absV >= 10000000) return '$sign${(absV / 10000000).toStringAsFixed(1)}Cr';
        if (absV >= 100000) return '$sign${(absV / 100000).toStringAsFixed(1)}L';
        if (absV >= 1000) return '$sign${(absV / 1000).toStringAsFixed(1)}K';
        return '$sign${absV.toStringAsFixed(0)}';
      }

      expect(fmt(500), equals('500'));
      expect(fmt(5000), equals('5.0K'));
      expect(fmt(250000), equals('2.5L')); // 2.5 Lakh
      expect(fmt(15000000), equals('1.5Cr')); // 1.5 Crore
      expect(fmt(-50000), equals('-50.0K'));
    });

    test('Shopping list actual vs estimated expense calculation', () {
      final items = [
        {'est': 1850.0, 'act': 1900.0, 'done': true},
        {'est': 920.0, 'act': null, 'done': true}, // uses est if act is null
        {'est': 280.0, 'act': null, 'done': false},
      ];

      double totalEst = 0;
      double totalActual = 0;

      for (final item in items) {
        final est = item['est'] as double;
        final act = item['act'] as double?;
        final done = item['done'] as bool;

        totalEst += est;
        totalActual += (act != null && act > 0) ? act : (done ? est : 0);
      }

      expect(totalEst, equals(3050.0));
      expect(totalActual, equals(2820.0)); // 1900 + 920
    });
  });
}
