import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
@HiveType(typeId: 14)
class UserModel with _$UserModel {
  const factory UserModel({
    @HiveField(0) required String id,
    @HiveField(1) required String email,
    @HiveField(2) String? displayName,
    @HiveField(3) String? photoURL,
    @HiveField(4) UserSettings? settings,

    @HiveField(6) DateTime? createdAt,
    @HiveField(7) DateTime? updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

@freezed
@HiveType(typeId: 15)
class UserSettings with _$UserSettings {
  const factory UserSettings({
    @HiveField(0) @Default('BDT') String currency,
    @HiveField(1) @Default('৳') String currencySymbol,
    @HiveField(2) @Default('en') String language,
    @HiveField(3) @Default(false) bool darkMode,
    @HiveField(4) @Default('#2D7A7B') String accentColor,
    @HiveField(5) @Default(false) bool rolloverBudget,
    @HiveField(6) @Default(true) bool smsAutoImport,
    @HiveField(7) @Default(false) bool biometricEnabled,
    @HiveField(8) @Default(true) bool notificationsEnabled,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}


