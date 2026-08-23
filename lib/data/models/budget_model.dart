import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'transaction_model.dart';

part 'budget_model.freezed.dart';
part 'budget_model.g.dart';

@freezed
@HiveType(typeId: 5)
class BudgetModel with _$BudgetModel {
  const factory BudgetModel({
    @HiveField(0) required String id,
    @HiveField(1) required String categoryId,
    @HiveField(2) required int amount,
    @HiveField(3) required DateTime month,
    @HiveField(5) @Default(false) bool rollover,
    @HiveField(6) @Default(0) int rolledAmount,
    @HiveField(7) DateTime? createdAt,
    @HiveField(8) DateTime? updatedAt,
  }) = _BudgetModel;

  factory BudgetModel.fromJson(Map<String, dynamic> json) =>
      _$BudgetModelFromJson(json);
}

extension BudgetSpentExtension on BudgetModel {
  int getSpent(List<TransactionModel> transactions) {
    return transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            !t.isDeleted &&
            t.categoryId == categoryId &&
            t.date.year == month.year &&
            t.date.month == month.month)
        .fold<int>(0, (sum, t) => sum + t.amount);
  }
}
