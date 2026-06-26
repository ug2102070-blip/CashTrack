import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'split_expense_model.freezed.dart';
part 'split_expense_model.g.dart';

@freezed
@HiveType(typeId: 18)
class SplitGroup with _$SplitGroup {
  const factory SplitGroup({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required List<String> members,
    @HiveField(3) required DateTime createdAt,
    @HiveField(4) DateTime? updatedAt,
  }) = _SplitGroup;

  factory SplitGroup.fromJson(Map<String, dynamic> json) =>
      _$SplitGroupFromJson(json);
}

@freezed
@HiveType(typeId: 19)
class SplitExpense with _$SplitExpense {
  const factory SplitExpense({
    @HiveField(0) required String id,
    @HiveField(1) required String groupId,
    @HiveField(2) required String description,
    @HiveField(3) required double amount,
    @HiveField(4) required String paidBy,
    @HiveField(5) required List<String> splitAmong,
    @HiveField(6) required DateTime date,
    @HiveField(7) DateTime? createdAt,
    @HiveField(8) DateTime? updatedAt,
  }) = _SplitExpense;

  factory SplitExpense.fromJson(Map<String, dynamic> json) =>
      _$SplitExpenseFromJson(json);
}

class SplitSettlement {
  final String from;
  final String to;
  final double amount;

  SplitSettlement({
    required this.from,
    required this.to,
    required this.amount,
  });

  static List<SplitSettlement> calculate(
    List<SplitExpense> expenses,
    List<String> members,
  ) {
    final balances = <String, double>{};
    for (final member in members) {
      balances[member] = 0.0;
    }

    for (final expense in expenses) {
      final share = expense.splitAmong.isEmpty
          ? 0.0
          : expense.amount / expense.splitAmong.length;
      final payer = expense.paidBy;
      balances[payer] = (balances[payer] ?? 0) + expense.amount;
      for (final member in expense.splitAmong) {
        balances[member] = (balances[member] ?? 0) - share;
      }
    }

    final debtors = balances.entries
        .where((entry) => entry.value < -0.01)
        .map((entry) => MapEntry(entry.key, -entry.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final creditors = balances.entries
        .where((entry) => entry.value > 0.01)
        .map((entry) => MapEntry(entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final settlements = <SplitSettlement>[];
    var debtorIndex = 0;
    var creditorIndex = 0;

    while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
      final debtor = debtors[debtorIndex];
      final creditor = creditors[creditorIndex];
      final amount = min(debtor.value, creditor.value);
      settlements.add(SplitSettlement(
        from: debtor.key,
        to: creditor.key,
        amount: amount,
      ));

      debtors[debtorIndex] = MapEntry(debtor.key, debtor.value - amount);
      creditors[creditorIndex] =
          MapEntry(creditor.key, creditor.value - amount);

      if (debtors[debtorIndex].value <= 0.01) debtorIndex++;
      if (creditors[creditorIndex].value <= 0.01) creditorIndex++;
    }

    return settlements;
  }
}

extension SplitGroupExtension on SplitGroup {
  String getUserMemberName(Map<String, String> profile) {
    final fullName = (profile['fullName'] ?? '').trim();
    final email = (profile['email'] ?? '').trim();
    final candidates = <String>{
      'You',
      'you',
      if (fullName.isNotEmpty) fullName,
      if (fullName.isNotEmpty) fullName.split(' ').first,
      if (email.isNotEmpty) email,
      if (email.isNotEmpty) email.split('@').first,
    };
    for (final member in members) {
      if (candidates.any((c) => c.toLowerCase() == member.toLowerCase())) {
        return member;
      }
    }
    return 'You';
  }
}

