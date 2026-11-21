import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DPS & Financial Calculations Tests', () {
    test('DPS 5000 BDT monthly at 8.5% for 5 years with 5% TIN AIT', () {
      const double monthlyDeposit = 5000;
      const double annualRate = 8.5;
      const int months = 5 * 12; // 60 months
      const double monthlyRate = annualRate / 1200.0;

      // Compounding maturity formula
      final grossMaturity = monthlyDeposit *
          ((pow(1 + monthlyRate, months) - 1) / monthlyRate) *
          (1 + monthlyRate);

      const totalDeposit = monthlyDeposit * months;
      final grossProfit = grossMaturity - totalDeposit;
      final aitTax5 = grossProfit * 0.05;
      final netMaturity5 = grossMaturity - aitTax5;

      expect(totalDeposit, equals(300000.0));
      expect(grossMaturity, greaterThan(370000.0));
      expect(grossMaturity, lessThan(380000.0));
      expect(netMaturity5, greaterThan(368000.0));
    });

    test('Sanchayapatra Paribar 10 Lakhs calculation with 10% AIT', () {
      const double investAmount = 1000000; // 10 Lakhs (Slab 1: 11.52%)
      const double slab1Rate = 11.52;

      const annualProfit = investAmount * (slab1Rate / 100.0);
      expect(annualProfit, equals(115200.0));

      // Monthly gross profit
      const grossMonthly = annualProfit / 12.0;
      expect(grossMonthly, equals(9600.0));

      // Above 5 Lakhs: AIT is 10%
      const monthlyAit = grossMonthly * 0.10;
      expect(monthlyAit, equals(960.0));

      // Net monthly payout
      const netMonthly = grossMonthly - monthlyAit;
      expect(netMonthly, equals(8640.0));
    });

    test('Sanchayapatra 3-Month Profit 20 Lakhs tiered slab calculation', () {
      // 20 Lakhs investment:
      // Slab 1 (Up to 15L): 11.04%
      // Slab 2 (15L to 30L): 10.00%
      const s1 = 1500000 * (11.04 / 100.0);
      const s2 = 500000 * (10.00 / 100.0);
      const totalAnnualProfit = s1 + s2;

      expect(totalAnnualProfit, equals(165600 + 50000)); // 215,600

      // Quarterly gross payout
      const grossQuarterly = totalAnnualProfit / 4.0;
      expect(grossQuarterly, equals(53900.0));

      // 10% AIT
      const netQuarterly = grossQuarterly * 0.90;
      expect(netQuarterly, equals(48510.0));
    });

    test('Zakat 2.5% calculation on net eligible wealth above Nisab', () {
      const double cash = 250000;
      const double bank = 400000;
      const double goldValue = 200000;
      const double immediateDebts = 50000;

      const double silverRatePerBhori = 2400;
      const double nisabThreshold = 52.5 * silverRatePerBhori; // 126,000 BDT

      const double netZakatable = (cash + bank + goldValue) - immediateDebts; // 800,000 BDT
      expect(netZakatable, greaterThan(nisabThreshold));

      const double zakatDue = netZakatable * 0.025; // 2.5%
      expect(zakatDue, equals(20000.0));
    });
  });
}
