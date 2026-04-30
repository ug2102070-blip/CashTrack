// lib/data/models/transaction_model.dart
import 'package:hive/hive.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

@freezed
@HiveType(typeId: 0)
class TransactionModel with _$TransactionModel {
  const factory TransactionModel({
    @HiveField(0) required String id,
    @HiveField(1) required TransactionType type,
    @HiveField(2) required double amount,
    @HiveField(3) required String categoryId,
    @HiveField(4) required String accountId,
    @HiveField(5) required DateTime date,
    @HiveField(6) String? note,
    @HiveField(7) String? receiptUrl,
    @HiveField(8) @Default(false) bool isRecurring,
    @HiveField(9) RecurringType? recurringType,
    @HiveField(10) @Default(false) bool isSynced,
    @HiveField(11) @Default(false) bool isDeleted,
    @HiveField(12) DateTime? createdAt,
    @HiveField(13) DateTime? updatedAt,
    @HiveField(14) String? smsId,
    @HiveField(15) String? toAccountId, // For transfers
    @HiveField(16) @Default([]) List<String> tags, // For SMS auto-categorization
    @HiveField(17) @Default(0.0) double confidenceScore, // SMS categorization confidence
  }) = _TransactionModel;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);
}

@HiveType(typeId: 1)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
  @HiveField(2)
  transfer,
  @HiveField(3)
  lent,
  @HiveField(4)
  borrowed,
}

@HiveType(typeId: 2)
enum RecurringType {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  yearly,
}
