import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'budget_model.freezed.dart';
part 'budget_model.g.dart';

@freezed
@HiveType(typeId: 5)
class BudgetModel with _$BudgetModel {
  const factory BudgetModel({
    @HiveField(0) required String id,
    @HiveField(1) required String categoryId,
    @HiveField(2) required double amount,
    @HiveField(3) required DateTime month,
    @HiveField(4) @Default(0) double spent,
    @HiveField(5) @Default(false) bool rollover,
    @HiveField(6) @Default(0) double rolledAmount,
    @HiveField(7) DateTime? createdAt,
    @HiveField(8) DateTime? updatedAt,
  }) = _BudgetModel;

  factory BudgetModel.fromJson(Map<String, dynamic> json) =>
      _$BudgetModelFromJson(json);
}
