import 'package:flutter_test/flutter_test.dart';
import 'package:cashtrack/services/statement_parser_service.dart';
import 'package:cashtrack/data/models/transaction_model.dart';
import 'hive_test_setup.dart';

void main() {
  setUp(() async {
    await initializeCashtrackRepositoriesForWidgetTest();
  });

  group('StatementParserService Tests', () {
    test('parses bKash statement format with TrxID and amounts', () async {
      const csvData = '''
Date,TrxID,Transaction Type,Amount,Balance
15/10/2026 14:30,BL782910AK,Send Money to 01711000000,500.00,12500.00
16/10/2026 10:15,BL992100ZX,Mobile Recharge to Grameenphone,100.00,12400.00
17/10/2026 18:00,BL443211MN,Cash In from Agent 01811223344,2000.00,14400.00
''';

      final result = await StatementParserService().parseCsvContent(csvData);
      expect(result.isSuccess, isTrue);
      expect(result.detectedFormat, 'bKash Statement');
      expect(result.items.length, 3);

      final sendMoney = result.items[0];
      expect(sendMoney.trxId, 'BL782910AK');
      expect(sendMoney.type, TransactionType.expense);
      expect(sendMoney.amount, 50000); // 500.00 * 100 Paisa
      expect(sendMoney.amountInTaka, 500.00);

      final recharge = result.items[1];
      expect(recharge.suggestedCategory, 'Utilities');
      expect(recharge.amount, 10000);

      final cashIn = result.items[2];
      expect(cashIn.type, TransactionType.income);
      expect(cashIn.amount, 200000);
    });

    test('parses Bangladeshi Bank Statement with Debit/Credit columns', () async {
      const csvData = '''
Account Statement: DBBL Savings Account 108.110.12345
Date,Particulars,Cheque No,Debit,Credit,Balance
2026-10-01,Monthly Salary from XYZ Ltd,,0.00,75000.00,75000.00
2026-10-03,Shwapno Super Shop Card POS,,4500.00,0.00,70500.00
2026-10-05,ATM Cash Withdrawal,CHQ001,10000.00,0.00,60500.00
''';

      final result = await StatementParserService().parseCsvContent(csvData);
      expect(result.isSuccess, isTrue);
      expect(result.detectedFormat, 'Bank Statement (Debit/Credit)');
      expect(result.items.length, 3);

      final salary = result.items[0];
      expect(salary.type, TransactionType.income);
      expect(salary.amount, 7500000); // 75,000 * 100
      expect(salary.suggestedCategory, 'Salary');

      final shwapno = result.items[1];
      expect(shwapno.type, TransactionType.expense);
      expect(shwapno.amount, 450000);
      expect(shwapno.suggestedCategory, 'Groceries');

      final atm = result.items[2];
      expect(atm.type, TransactionType.expense);
      expect(atm.amount, 1000000);
    });

    test('handles empty or malformed statement gracefully', () async {
      final result = await StatementParserService().parseCsvContent('');
      expect(result.isSuccess, isFalse);
      expect(result.items, isEmpty);
    });
  });
}
