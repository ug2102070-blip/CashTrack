import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'investment_model.freezed.dart';
part 'investment_model.g.dart';

@freezed
@HiveType(typeId: 12)
class InvestmentModel with _$InvestmentModel {
  const factory InvestmentModel({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required InvestmentType type,
    @HiveField(3) required double investedAmount,
    @HiveField(4) required double currentValue,
    @HiveField(5) @Default(0) double expectedReturn,
    @HiveField(6) required DateTime startDate,
    @HiveField(7) DateTime? maturityDate,
    @HiveField(8) String? note,
    @HiveField(9) DateTime? createdAt,
    @HiveField(10) DateTime? updatedAt,
  }) = _InvestmentModel;

  factory InvestmentModel.fromJson(Map<String, dynamic> json) =>
      _$InvestmentModelFromJson(json);
}

@HiveType(typeId: 13)
enum InvestmentType {
  @HiveField(0)
  mutualFund,
  @HiveField(1)
  stock,
  @HiveField(2)
  fixedDeposit,
  @HiveField(3)
  gold,
  @HiveField(4)
  dps,
  @HiveField(5)
  others,
}
