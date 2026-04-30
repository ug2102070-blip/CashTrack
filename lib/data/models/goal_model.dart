// lib/data/models/goal_model.dart
// ==========================================

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'goal_model.freezed.dart';
part 'goal_model.g.dart';

@freezed
@HiveType(typeId: 8)
class GoalModel with _$GoalModel {
  const factory GoalModel({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required double targetAmount,
    @HiveField(3) @Default(0) double currentAmount,
    @HiveField(4) DateTime? deadline,
    @HiveField(5) String? icon,
    @HiveField(6) String? colorHex,
    @HiveField(7) @Default(false) bool isCompleted,
    @HiveField(8) DateTime? createdAt,
    @HiveField(9) DateTime? updatedAt,
  }) = _GoalModel;

  factory GoalModel.fromJson(Map<String, dynamic> json) =>
      _$GoalModelFromJson(json);
}
