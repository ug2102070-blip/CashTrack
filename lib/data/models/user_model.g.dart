// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 14;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      email: fields[1] as String,
      displayName: fields[2] as String?,
      photoURL: fields[3] as String?,
      settings: fields[4] as UserSettings?,
      stats: fields[5] as UserStats?,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.displayName)
      ..writeByte(3)
      ..write(obj.photoURL)
      ..writeByte(4)
      ..write(obj.settings)
      ..writeByte(5)
      ..write(obj.stats)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 15;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      currency: fields[0] as String,
      currencySymbol: fields[1] as String,
      language: fields[2] as String,
      darkMode: fields[3] as bool,
      accentColor: fields[4] as String,
      rolloverBudget: fields[5] as bool,
      smsAutoImport: fields[6] as bool,
      biometricEnabled: fields[7] as bool,
      notificationsEnabled: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.currency)
      ..writeByte(1)
      ..write(obj.currencySymbol)
      ..writeByte(2)
      ..write(obj.language)
      ..writeByte(3)
      ..write(obj.darkMode)
      ..writeByte(4)
      ..write(obj.accentColor)
      ..writeByte(5)
      ..write(obj.rolloverBudget)
      ..writeByte(6)
      ..write(obj.smsAutoImport)
      ..writeByte(7)
      ..write(obj.biometricEnabled)
      ..writeByte(8)
      ..write(obj.notificationsEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserStatsAdapter extends TypeAdapter<UserStats> {
  @override
  final int typeId = 16;

  @override
  UserStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserStats(
      totalBalance: fields[0] as double,
      totalIncome: fields[1] as double,
      totalExpense: fields[2] as double,
      transactionCount: fields[3] as int,
      lastSyncTime: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserStats obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.totalBalance)
      ..writeByte(1)
      ..write(obj.totalIncome)
      ..writeByte(2)
      ..write(obj.totalExpense)
      ..writeByte(3)
      ..write(obj.transactionCount)
      ..writeByte(4)
      ..write(obj.lastSyncTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      settings: json['settings'] == null
          ? null
          : UserSettings.fromJson(json['settings'] as Map<String, dynamic>),
      stats: json['stats'] == null
          ? null
          : UserStats.fromJson(json['stats'] as Map<String, dynamic>),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'displayName': instance.displayName,
      'photoURL': instance.photoURL,
      'settings': instance.settings,
      'stats': instance.stats,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$UserSettingsImpl _$$UserSettingsImplFromJson(Map<String, dynamic> json) =>
    _$UserSettingsImpl(
      currency: json['currency'] as String? ?? 'BDT',
      currencySymbol: json['currencySymbol'] as String? ?? '৳',
      language: json['language'] as String? ?? 'en',
      darkMode: json['darkMode'] as bool? ?? false,
      accentColor: json['accentColor'] as String? ?? '#2D7A7B',
      rolloverBudget: json['rolloverBudget'] as bool? ?? false,
      smsAutoImport: json['smsAutoImport'] as bool? ?? true,
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    );

Map<String, dynamic> _$$UserSettingsImplToJson(_$UserSettingsImpl instance) =>
    <String, dynamic>{
      'currency': instance.currency,
      'currencySymbol': instance.currencySymbol,
      'language': instance.language,
      'darkMode': instance.darkMode,
      'accentColor': instance.accentColor,
      'rolloverBudget': instance.rolloverBudget,
      'smsAutoImport': instance.smsAutoImport,
      'biometricEnabled': instance.biometricEnabled,
      'notificationsEnabled': instance.notificationsEnabled,
    };

_$UserStatsImpl _$$UserStatsImplFromJson(Map<String, dynamic> json) =>
    _$UserStatsImpl(
      totalBalance: (json['totalBalance'] as num?)?.toDouble() ?? 0,
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0,
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0,
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
      lastSyncTime: json['lastSyncTime'] == null
          ? null
          : DateTime.parse(json['lastSyncTime'] as String),
    );

Map<String, dynamic> _$$UserStatsImplToJson(_$UserStatsImpl instance) =>
    <String, dynamic>{
      'totalBalance': instance.totalBalance,
      'totalIncome': instance.totalIncome,
      'totalExpense': instance.totalExpense,
      'transactionCount': instance.transactionCount,
      'lastSyncTime': instance.lastSyncTime?.toIso8601String(),
    };
