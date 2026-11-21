// lib/services/statement_parser_service.dart
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../core/utils/logger.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/transaction_repository.dart';

class ParsedStatementItem {
  final String id;
  final DateTime date;
  final TransactionType type;
  final int amount; // Stored in Paisa (1 BDT = 100 Paisa)
  final String description;
  final String? trxId;
  final String suggestedCategory;
  final bool isDuplicate;
  bool isSelected;

  ParsedStatementItem({
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.description,
    this.trxId,
    required this.suggestedCategory,
    this.isDuplicate = false,
    bool? isSelected,
  }) : isSelected = isSelected ?? !isDuplicate;

  double get amountInTaka => amount / 100.0;
}

class StatementParseResult {
  final List<ParsedStatementItem> items;
  final String detectedFormat;
  final bool isSuccess;
  final String? errorMessage;

  const StatementParseResult({
    required this.items,
    required this.detectedFormat,
    this.isSuccess = true,
    this.errorMessage,
  });

  factory StatementParseResult.failure(String message) {
    return StatementParseResult(
      items: const [],
      detectedFormat: 'Unknown',
      isSuccess: false,
      errorMessage: message,
    );
  }

  int get totalIncomePaisa => items
      .where((i) => i.isSelected && i.type == TransactionType.income)
      .fold(0, (sum, i) => sum + i.amount);

  int get totalExpensePaisa => items
      .where((i) => i.isSelected && i.type == TransactionType.expense)
      .fold(0, (sum, i) => sum + i.amount);

  int get selectedCount => items.where((i) => i.isSelected).length;
}

class StatementParserService {
  StatementParserService._internal();
  static final StatementParserService _instance =
      StatementParserService._internal();
  factory StatementParserService() => _instance;

  final TransactionRepository _txRepo = TransactionRepository();

  /// Parses CSV statement content from bKash, Bangladeshi banks, or generic trackers
  Future<StatementParseResult> parseCsvContent(String rawContent) async {
    try {
      if (rawContent.trim().isEmpty) {
        return StatementParseResult.failure('The statement file is empty.');
      }

      // 1. Convert CSV to 2D list of strings
      const converter = CsvToListConverter(
        shouldParseNumbers: false,
        allowInvalid: true,
      );
      final List<List<dynamic>> rows = converter.convert(rawContent);

      if (rows.isEmpty) {
        return StatementParseResult.failure('No rows found in CSV file.');
      }

      // 2. Locate the header row (skip top bank metadata like "Account statement...")
      int headerRowIndex = -1;
      List<String> normalizedHeaders = [];

      for (int i = 0; i < rows.length && i < 15; i++) {
        final row = rows[i].map((e) => e.toString().trim().toLowerCase()).toList();
        final hasDate = row.any((c) => c.contains('date') || c.contains('তারিখ'));
        final hasAmountOrMoney = row.any((c) =>
            c.contains('amount') ||
            c.contains('debit') ||
            c.contains('credit') ||
            c.contains('withdrawal') ||
            c.contains('deposit') ||
            c.contains('টাকা'));

        if (hasDate && hasAmountOrMoney) {
          headerRowIndex = i;
          normalizedHeaders = row;
          break;
        }
      }

      if (headerRowIndex == -1) {
        return StatementParseResult.failure(
          'Could not detect standard statement columns (Date and Amount/Debit/Credit).',
        );
      }

      // 3. Detect statement schema type
      final isBkash = normalizedHeaders.any((h) => h.contains('trxid') || h.contains('trx id')) ||
          rawContent.toLowerCase().contains('bkash');
      final isBankDebitCredit = normalizedHeaders.any((h) => h.contains('debit') || h.contains('withdrawal')) &&
          normalizedHeaders.any((h) => h.contains('credit') || h.contains('deposit'));

      final detectedFormat = isBkash
          ? 'bKash Statement'
          : (isBankDebitCredit ? 'Bank Statement (Debit/Credit)' : 'Standard CSV');

      // 4. Fetch existing transactions to detect duplicates
      await _txRepo.init();
      final existingTransactions = _txRepo.getAllTransactions();
      final Set<String> existingTrxIds = existingTransactions
          .where((t) => t.smsId != null && t.smsId!.isNotEmpty)
          .map((t) => t.smsId!.toLowerCase())
          .toSet();

      final List<ParsedStatementItem> parsedItems = [];
      int rowSequence = 0;

      for (int r = headerRowIndex + 1; r < rows.length; r++) {
        final rawRow = rows[r];
        if (rawRow.isEmpty || rawRow.every((c) => c.toString().trim().isEmpty)) {
          continue;
        }

        final item = _parseRow(
          rawRow: rawRow,
          headers: normalizedHeaders,
          isBkash: isBkash,
          isBankDebitCredit: isBankDebitCredit,
          sequence: ++rowSequence,
          existingTransactions: existingTransactions,
          existingTrxIds: existingTrxIds,
        );

        if (item != null) {
          parsedItems.add(item);
        }
      }

      if (parsedItems.isEmpty) {
        return StatementParseResult.failure('No valid transaction entries could be extracted.');
      }

      return StatementParseResult(
        items: parsedItems,
        detectedFormat: detectedFormat,
      );
    } catch (e, stack) {
      AppLogger.e('Statement parsing failed: $e\n$stack');
      return StatementParseResult.failure('Failed to parse statement: $e');
    }
  }

  ParsedStatementItem? _parseRow({
    required List<dynamic> rawRow,
    required List<String> headers,
    required bool isBkash,
    required bool isBankDebitCredit,
    required int sequence,
    required List<TransactionModel> existingTransactions,
    required Set<String> existingTrxIds,
  }) {
    try {
      // Find Date
      final dateIdx = headers.indexWhere((h) => h.contains('date') || h.contains('তারিখ'));
      if (dateIdx == -1 || dateIdx >= rawRow.length) return null;
      final date = _parseDateTime(rawRow[dateIdx].toString().trim());
      if (date == null) return null;

      // Find Description / Particulars
      final descIdx = headers.indexWhere((h) =>
          h.contains('particular') ||
          h.contains('description') ||
          h.contains('details') ||
          h.contains('narration') ||
          h.contains('note') ||
          h.contains('transaction type') ||
          h.contains('বিবরণ'));
      String description = descIdx != -1 && descIdx < rawRow.length
          ? rawRow[descIdx].toString().trim()
          : 'Statement Item';

      // Find TrxID if present
      final trxIdx = headers.indexWhere((h) => h.contains('trx') || h.contains('ref'));
      String? trxId;
      if (trxIdx != -1 && trxIdx < rawRow.length) {
        final rawTrx = rawRow[trxIdx].toString().trim();
        if (rawTrx.isNotEmpty && rawTrx.toLowerCase() != 'null') {
          trxId = rawTrx;
        }
      }

      TransactionType type = TransactionType.expense;
      int amountPaisa = 0;

      if (isBankDebitCredit) {
        final debitIdx = headers.indexWhere((h) => h.contains('debit') || h.contains('withdrawal') || h.contains('dr'));
        final creditIdx = headers.indexWhere((h) => h.contains('credit') || h.contains('deposit') || h.contains('cr'));

        final debitVal = debitIdx != -1 && debitIdx < rawRow.length
            ? _extractNumeric(rawRow[debitIdx].toString())
            : 0.0;
        final creditVal = creditIdx != -1 && creditIdx < rawRow.length
            ? _extractNumeric(rawRow[creditIdx].toString())
            : 0.0;

        if (creditVal > 0) {
          type = TransactionType.income;
          amountPaisa = (creditVal * 100).round();
        } else if (debitVal > 0) {
          type = TransactionType.expense;
          amountPaisa = (debitVal * 100).round();
        } else {
          return null; // Empty row or zero value
        }
      } else {
        // Generic or bKash
        final amountIdx = headers.indexWhere((h) =>
            (h.contains('amount') || h.contains('টাকা')) && !h.contains('balance'));
        if (amountIdx == -1 || amountIdx >= rawRow.length) return null;
        final numVal = _extractNumeric(rawRow[amountIdx].toString());
        if (numVal <= 0) return null;
        amountPaisa = (numVal * 100).round();

        // Determine type
        final typeIdx = headers.indexWhere((h) => h.contains('type'));
        final rawTypeStr = typeIdx != -1 && typeIdx < rawRow.length
            ? rawRow[typeIdx].toString().toLowerCase()
            : '';

        final lowerDesc = '$description $rawTypeStr'.toLowerCase();
        if (lowerDesc.contains('receive') ||
            lowerDesc.contains('cash in') ||
            lowerDesc.contains('add money') ||
            lowerDesc.contains('deposit') ||
            lowerDesc.contains('salary') ||
            lowerDesc.contains('income') ||
            lowerDesc.contains('credit')) {
          type = TransactionType.income;
        } else {
          type = TransactionType.expense;
        }
      }

      // Suggest category
      final suggestedCategory = _suggestCategory(description);

      // Duplicate check: Match against TrxID OR same date & exact amount
      bool isDuplicate = false;
      if (trxId != null && existingTrxIds.contains(trxId.toLowerCase())) {
        isDuplicate = true;
      } else {
        isDuplicate = existingTransactions.any((t) =>
            !t.isDeleted &&
            t.type == type &&
            t.amount == amountPaisa &&
            t.date.year == date.year &&
            t.date.month == date.month &&
            t.date.day == date.day);
      }

      return ParsedStatementItem(
        id: 'stmt_${date.millisecondsSinceEpoch}_$sequence',
        date: date,
        type: type,
        amount: amountPaisa,
        description: description,
        trxId: trxId,
        suggestedCategory: suggestedCategory,
        isDuplicate: isDuplicate,
      );
    } catch (_) {
      return null;
    }
  }

  double _extractNumeric(String raw) {
    final cleaned = raw.replaceAll(',', '').replaceAll('৳', '').replaceAll('Tk', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  DateTime? _parseDateTime(String raw) {
    final trimmed = raw.trim();
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso;

    final formats = [
      DateFormat('dd/MM/yyyy HH:mm:ss'),
      DateFormat('dd/MM/yyyy HH:mm'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('dd-MM-yyyy HH:mm:ss'),
      DateFormat('dd-MM-yyyy'),
      DateFormat('yyyy-MM-dd HH:mm:ss'),
      DateFormat('yyyy-MM-dd'),
      DateFormat('MM/dd/yyyy'),
      DateFormat('dd MMM yyyy'),
      DateFormat('dd-MMM-yyyy'),
    ];

    for (final f in formats) {
      try {
        return f.parseStrict(trimmed);
      } catch (_) {}
    }
    return null;
  }

  String _suggestCategory(String description) {
    final d = description.toLowerCase();
    if (d.contains('recharge') || d.contains('airtel') || d.contains('grameenphone') ||
        d.contains('robi') || d.contains('banglalink') || d.contains('teletalk')) {
      return 'Utilities';
    }
    if (d.contains('shwapno') || d.contains('agora') || d.contains('unimart') ||
        d.contains('meena') || d.contains('bazaar') || d.contains('grocery') || d.contains('chaldal')) {
      return 'Groceries';
    }
    if (d.contains('pathao') || d.contains('uber') || d.contains('fuel') ||
        d.contains('cng') || d.contains('transport') || d.contains('petrol')) {
      return 'Transportation';
    }
    if (d.contains('kfc') || d.contains('pizza') || d.contains('restaurant') ||
        d.contains('burger') || d.contains('food') || d.contains('cafe')) {
      return 'Food & Dining';
    }
    if (d.contains('daraz') || d.contains('shopping') || d.contains('cloth') ||
        d.contains('apex') || d.contains('bata') || d.contains('aarong')) {
      return 'Shopping';
    }
    if (d.contains('pharmacy') || d.contains('lazz') || d.contains('hospital') ||
        d.contains('doctor') || d.contains('medical')) {
      return 'Medical';
    }
    if (d.contains('salary') || d.contains('allowance') || d.contains('remittance')) {
      return 'Salary';
    }
    if (d.contains('desco') || d.contains('dpdc') || d.contains('wasa') ||
        d.contains('titas') || d.contains('internet') || d.contains('wifi') || d.contains('electricity')) {
      return 'Utilities';
    }
    return 'General';
  }
}
