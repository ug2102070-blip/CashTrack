// ==========================================
// lib/data/models/account_model.dart
// ==========================================

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'account_model.freezed.dart';
part 'account_model.g.dart';

@freezed
@HiveType(typeId: 6)
class AccountModel with _$AccountModel {
  const factory AccountModel({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required String nameBn,
    @HiveField(3) required AccountType type,
    @HiveField(4) required double balance,
    @HiveField(5) String? icon,
    @HiveField(6) String? colorHex,
    @HiveField(7) @Default(false) bool isDefault,
    @HiveField(8) DateTime? createdAt,
    @HiveField(9) DateTime? updatedAt,
    @HiveField(10)
    String? nickname, // User-editable custom name (e.g. "Salary Account")
    @HiveField(11) String? userId, // Track which user owns this account
    @HiveField(12) String? accountNumber,
    @HiveField(13) String? cardType,
    @HiveField(14) String? cardIssuer,
    @HiveField(15) String? cardholderName,
    @HiveField(16) double? creditLimit,
    @HiveField(17) int? billingDay,
    @HiveField(18) int? paymentDueDay,
  }) = _AccountModel;

  factory AccountModel.fromJson(Map<String, dynamic> json) =>
      _$AccountModelFromJson(json);
}

@HiveType(typeId: 7)
enum AccountType {
  @HiveField(0)
  cash,
  @HiveField(1)
  bank,
  @HiveField(2)
  mfs, // Mobile Financial Services
  @HiveField(3)
  creditCard,
}

class DefaultAccounts {
  static final List<AccountModel> accounts = [
    AccountModel(
      id: 'acc_cash',
      name: 'Cash',
      nameBn: 'নগদ',
      type: AccountType.cash,
      balance: 0,
      icon: '💵',
      colorHex: '#10B981',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    AccountModel(
      id: 'acc_bkash',
      name: 'bKash',
      nameBn: 'বিকাশ',
      type: AccountType.mfs,
      balance: 0,
      icon: '📱',
      colorHex: '#E2136E',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    AccountModel(
      id: 'acc_nagad',
      name: 'Nagad',
      nameBn: 'নগদ (ডিজিটাল)',
      type: AccountType.mfs,
      balance: 0,
      icon: '📲',
      colorHex: '#F6921E',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    AccountModel(
      id: 'acc_rocket',
      name: 'Rocket',
      nameBn: 'রকেট',
      type: AccountType.mfs,
      balance: 0,
      icon: '🚀',
      colorHex: '#8C1D8C',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    AccountModel(
      id: 'acc_upay',
      name: 'Upay',
      nameBn: 'উপায়',
      type: AccountType.mfs,
      balance: 0,
      icon: '💚',
      colorHex: '#00A651',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    AccountModel(
      id: 'acc_online',
      name: 'Bank / Other',
      nameBn: 'ব্যাংক / অন্যান্য',
      type: AccountType.bank,
      balance: 0,
      icon: '🏦',
      colorHex: '#3B82F6',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    AccountModel(
      id: 'acc_credit_card',
      name: 'Credit Card',
      nameBn: 'ক্রেডিট কার্ড',
      type: AccountType.creditCard,
      balance: 0,
      icon: '💳',
      colorHex: '#8B5CF6',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
  ];
}
