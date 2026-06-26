import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'debt_model.freezed.dart';
part 'debt_model.g.dart';

@freezed
@HiveType(typeId: 9)
class DebtModel with _$DebtModel {
  const factory DebtModel({
    @HiveField(0) required String id,
    @HiveField(1) required DebtType type,
    @HiveField(2) required String personName,
    @HiveField(3) required double amount,
    @HiveField(4) @Default(0) double paidAmount,
    @HiveField(5) DateTime? dueDate,
    @HiveField(6) String? note,
    @HiveField(7) @Default(false) bool isSettled,
    @HiveField(8) DateTime? createdAt,
    @HiveField(9) DateTime? updatedAt,
    // ── Smart Debt Agreement Fields ──────────────────────
    @HiveField(10) String? phoneNumber,
    @HiveField(11) @Default(AgreementStatus.pending) AgreementStatus agreementStatus,
    @HiveField(12) @Default(0) double penaltyRate,
    @HiveField(13) @Default(0) double penaltyAmount,
    @HiveField(14) String? agreementTerms,
    @HiveField(15) @Default(100) int trustScore,
    @HiveField(16) @Default(0) int remindersSent,
    @HiveField(17) DateTime? lastReminderAt,
    @HiveField(18) @Default(false) bool hasAgreement,
    @HiveField(19) String? paymentMethod,
  }) = _DebtModel;

  factory DebtModel.fromJson(Map<String, dynamic> json) =>
      _$DebtModelFromJson(json);
}

@HiveType(typeId: 10)
enum DebtType {
  @HiveField(0)
  lent, // Money you gave to someone
  @HiveField(1)
  borrowed, // Money you took from someone
}

@HiveType(typeId: 17)
enum AgreementStatus {
  @HiveField(0)
  pending, // Agreement not yet confirmed
  @HiveField(1)
  accepted, // Both parties agreed
  @HiveField(2)
  rejected, // Borrower rejected
  @HiveField(3)
  expired, // Deadline passed without payment
  @HiveField(4)
  completed, // Fully paid
}
