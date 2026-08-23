import 'package:flutter_test/flutter_test.dart';
import 'package:cashtrack/services/sms_service.dart';
import 'package:cashtrack/data/models/transaction_model.dart';
import 'hive_test_setup.dart';

void main() {
  setUpAll(() async {
    await initializeHiveForTests();
  });

  group('SmsService.parseFromText', () {
    // ── bKash & Nagad Tests ──────────────────────────────────────────────
    test('correctly parses English bKash received Send Money', () {
      const text = 'bKash You have received Tk 20.00 from 01712345678. Ref test. Fee Tk 0.00. Balance Tk 1020.00. TrxID ABC123XYZ';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 2000);
      expect(transaction.type, TransactionType.income);
      expect(transaction.accountId, 'acc_bkash');
    });

    test('correctly parses English Nagad received Send Money', () {
      const text = 'Nagad You have received Tk 20.00 from 01812345678. Current Balance: 520.00. TxnID: 99887766';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 2000);
      expect(transaction.type, TransactionType.income);
      expect(transaction.accountId, 'acc_nagad');
    });

    test('correctly parses Bangla bKash received Send Money', () {
      const text = 'bKash আপনি ০১৭১২৩৪৫৬৭৮ থেকে ২০.০০ টাকা পেয়েছেন। ব্যালেন্স ১০২০.০০ টাকা। TrxID ABC123XYZ';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 2000);
      expect(transaction.type, TransactionType.income);
      expect(transaction.accountId, 'acc_bkash');
    });

    test('correctly parses Bangla Nagad received Send Money', () {
      const text = 'Nagad আপনি ০১৮১২৩৪৫৬৭৮ থেকে ২০.০০ টাকা পেয়েছেন। ব্যালেন্স ৫২০.০০ টাকা। TxnID: 99887766';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 2000);
      expect(transaction.type, TransactionType.income);
      expect(transaction.accountId, 'acc_nagad');
    });

    test('correctly parses English bKash sent Send Money', () {
      const text = '16247 Send Money Tk 20.00 to 01712345678 successful. Fee Tk 0.00. Balance Tk 1000.00. TrxID XYZ123';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 2000);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.accountId, 'acc_bkash');
    });

    test('correctly parses Bangla bKash sent Send Money', () {
      const text = '16247 ০১৭১২৩৪৫৬৭৮ নম্বরে ২০.০০ টাকা সেন্ড মানি সফল হয়েছে। ফি ০.০০ টাকা। ব্যালেন্স ১০০০.০০ টাকা। TrxID XYZ123';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 2000);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.accountId, 'acc_bkash');
    });

    // ── Upay & Rocket Tests ──────────────────────────────────────────────
    test('correctly parses Upay mobile recharge', () {
      const text = 'upay Mobile Recharge of Tk 50.00 to 01912345678 successful. TxnID: 99283748. Balance: Tk 450.00.';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 5000);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.accountId, 'acc_upay');
      expect(transaction.categoryId, 'cat_mobile');
    });

    test('correctly parses Upay bill payment', () {
      const text = 'upay Bill Payment of Tk 1200.00 to DESCO successful. TxnID: 99112233. Balance: Tk 800.00.';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 120000);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.accountId, 'acc_upay');
      expect(transaction.categoryId, 'cat_bills');
    });

    test('correctly parses Rocket bill payment', () {
      const text = 'Rocket: You have paid successfully Tk 550.00 to DESCO. Bill No: 987654. TxnID: 88776655. Bal. Tk 120.00';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 55000);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.accountId, 'acc_rocket');
      expect(transaction.categoryId, 'cat_bills');
    });

    test('correctly parses Rocket Cash Out', () {
      const text = 'Cash Out of Tk 2000.00 successful from DBBL Agent 01711223344. Fee Tk 36.00. Balance Tk 4500.00. TxnID: 55443322';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 200000);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.accountId, 'acc_rocket');
    });

    // ── SureCash & mCash & OK Wallet Tests ───────────────────────────────
    test('correctly parses SureCash payment', () {
      const text = 'SureCash Payment of Tk 400.00 successful to Coaching. TrxID: SC12345. Bal: Tk 1500.00';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 40000);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.accountId, 'acc_online');
      expect(transaction.categoryId, 'cat_education'); // कोचिंग -> Education
    });

    test('correctly parses OK Wallet merchant payment', () {
      const text = 'OK Wallet Payment Tk 150.00 success to Merchant Shwapno. TxnID: OK998877. New Balance: Tk 1050.00';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 15000);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.accountId, 'acc_online');
      expect(transaction.categoryId, 'cat_grocery'); // Shwapno -> Grocery
    });

    // ── Bank SMS Test cases (Salary, EMI, Card Purchase, Remittance, Interest) ──
    test('correctly parses bank salary credit notification', () {
      const text = 'Dear Customer, your A/C has been credited with BDT 35,000.00 for Salary on 30-Jun-2026. Ref: Payroll.';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 3500000);
      expect(transaction.type, TransactionType.income);
      expect(transaction.accountId, 'acc_online');
      expect(transaction.categoryId, 'cat_salary');
    });

    test('correctly parses bank EMI debit notification', () {
      const text = 'Dear Customer, your A/C has been debited with BDT 5,500.00 for Loan EMI installment on 05-Jul-2026.';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 550000);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.accountId, 'acc_online');
      expect(transaction.categoryId, 'cat_bills'); // EMI falls under bills
    });

    test('correctly parses bank remittance receipt', () {
      const text = 'Remittance payout of BDT 50,000.00 received from Exchange House. Ref: Family support.';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 5000000);
      expect(transaction.type, TransactionType.income);
      expect(transaction.accountId, 'acc_online');
      expect(transaction.categoryId, 'cat_other_income');
    });

    test('correctly parses bank interest credited', () {
      const text = 'Interest credited to your A/C: BDT 250.50 on 30-Jun-2026. Balance BDT 85,250.50.';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 25050);
      expect(transaction.type, TransactionType.income);
      expect(transaction.accountId, 'acc_online');
      expect(transaction.categoryId, 'cat_other_income');
    });

    // ── Tests using the user's exact SMS format ──────────────────────────
    test('parses bKash Money Received with Amount: Tk format (10000)', () {
      const text = 'Money Received. Amount: Tk 10000.00 Sender: 01880202678 Ref: 0 TxnID: 75M5UOC0 Balance: Tk 36601.65 03/07/2026 18:31';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 1000000);
      expect(transaction.type, TransactionType.income);
    });

    test('parses bKash Money Received with Amount: Tk format (20)', () {
      const text = 'Money Received. Amount: Tk 20.00 Sender: 01317326820 Ref: N/A TxnID: 75LHJXJX Balance: Tk 26621.65 30/06/2026 12:55';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 2000);
      expect(transaction.type, TransactionType.income);
    });

    test('parses bKash Money Received title-only format', () {
      const text = 'Money Received. Amount: Tk 500.00';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 50000);
      expect(transaction.type, TransactionType.income);
    });

    test('parses amount with comma separator', () {
      const text = 'bKash You have received Tk 1,500.00 from 01712345678. Balance Tk 10,000.00.';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 150000);
      expect(transaction.type, TransactionType.income);
    });

    test('returns null for non-financial text', () {
      const text = 'Your OTP is 123456. Valid for 5 minutes.';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNull);
    });

    // ── User's Specific Nagad Formats ────────────────────────────────────
    test('correctly parses Nagad payment to Software Shop Ltd', () {
      const text = "Payment to 'Software Shop Ltd' is Successful. Amount: Tk 20.00 TxnID: 75NMBN1S Balance: Tk 32432.71 11/07/2026 17:44";
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 2000);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.accountId, 'acc_nagad');
      expect(transaction.note, contains('Software Shop Ltd'));
    });

    test('correctly parses Nagad Cash In', () {
      const text = 'Cash In Received. Amount: Tk 1000.00 Uddokta: 01890334239 TxnID: 75KVY4BN Balance: 26959.97 27/06/2026 18:10';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 100000);
      expect(transaction.type, TransactionType.income);
      expect(transaction.accountId, 'acc_nagad');
      expect(transaction.note, contains('01890334239'));
    });

    // ── User's Specific bKash Formats ────────────────────────────────────
    test('correctly parses bKash Bill successfully paid format', () {
      const text = 'Bill successfully paid. Biller: PALLI BIDYUT MM/YYYY: 062026 SMS Account: 1040124501630 Amount: Tk 469.00 Fee: Tk 0.00 TrxID: DFM6KN8GL8 at 22/06/2026 14:19';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 46900);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.accountId, 'acc_bkash');
    });

    test('correctly parses bKash Payment to Grameenphone format', () {
      const text = 'Payment of Tk 20.00 to Grameenphone Ltd-MyGP Direct Charge-RM50518 is successful. Balance Tk 19,319.13. TrxID DF42WGU5JU at 04/06/2026 16:35';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull);
      expect(transaction!.amount, 2000);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.accountId, 'acc_bkash');
      expect(transaction.note, contains('Grameenphone Ltd'));
    });

    // ── User's EXACT Failing SMS (Jul 13, 2026) ─────────────────────────
    test('parses exact user bKash SMS: received Tk 1527.75 from 01760713916', () {
      const text = 'You have received Tk 1,527.75 from 01760713916. Fee Tk 0.00. Balance Tk 14,991.71. TrxID DGD1CCCP0P at 13/07/2026 19:08';
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull,
          reason: 'Should parse bKash received money SMS with comma-formatted amount');
      expect(transaction!.amount, 152775,
          reason: 'Amount should be 1527.75 (comma removed from 1,527.75)');
      expect(transaction.type, TransactionType.income,
          reason: 'Should be income because "received" keyword present');
      expect(transaction.accountId, 'acc_bkash',
          reason: 'Should detect bKash because TrxID present');
      expect(transaction.note, contains('01760713916'),
          reason: 'Note should include sender phone number');
    });

    test('parses exact user Nagad Payment to Software Shop Ltd SMS (Aug 23, 2026)', () {
      const text = "Payment to 'Software Shop Ltd' is Successful.\nAmount: Tk 100.00\nTxnID: 75VCOYMN\nBalance: Tk 6378.56\n23/08/2026 22:48";
      final transaction = SmsService().parseFromText(text);
      expect(transaction, isNotNull,
          reason: 'Should parse Nagad payment SMS with newlines');
      expect(transaction!.amount, 10000,
          reason: 'Amount should be 10000 paisa (100.00 BDT)');
      expect(transaction.type, TransactionType.expense,
          reason: 'Payment to merchant should be expense');
      expect(transaction.accountId, 'acc_nagad',
          reason: 'TxnID format and keyword should identify Nagad');
      expect(transaction.note, contains('Software Shop Ltd'),
          reason: 'Note should include merchant name');
    });
  });
}
