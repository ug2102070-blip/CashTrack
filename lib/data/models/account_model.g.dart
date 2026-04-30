// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountModelAdapter extends TypeAdapter<AccountModel> {
  @override
  final int typeId = 6;

  @override
  AccountModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AccountModel(
      id: fields[0] as String,
      name: fields[1] as String,
      nameBn: fields[2] as String,
      type: fields[3] as AccountType,
      balance: fields[4] as double,
      icon: fields[5] as String?,
      colorHex: fields[6] as String?,
      isDefault: fields[7] as bool,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AccountModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.nameBn)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.balance)
      ..writeByte(5)
      ..write(obj.icon)
      ..writeByte(6)
      ..write(obj.colorHex)
      ..writeByte(7)
      ..write(obj.isDefault)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AccountTypeAdapter extends TypeAdapter<AccountType> {
  @override
  final int typeId = 7;

  @override
  AccountType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AccountType.cash;
      case 1:
        return AccountType.bank;
      case 2:
        return AccountType.mfs;
      default:
        return AccountType.cash;
    }
  }

  @override
  void write(BinaryWriter writer, AccountType obj) {
    switch (obj) {
      case AccountType.cash:
        writer.writeByte(0);
        break;
      case AccountType.bank:
        writer.writeByte(1);
        break;
      case AccountType.mfs:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AccountModelImpl _$$AccountModelImplFromJson(Map<String, dynamic> json) =>
    _$AccountModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      nameBn: json['nameBn'] as String,
      type: $enumDecode(_$AccountTypeEnumMap, json['type']),
      balance: (json['balance'] as num).toDouble(),
      icon: json['icon'] as String?,
      colorHex: json['colorHex'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$AccountModelImplToJson(_$AccountModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'nameBn': instance.nameBn,
      'type': _$AccountTypeEnumMap[instance.type]!,
      'balance': instance.balance,
      'icon': instance.icon,
      'colorHex': instance.colorHex,
      'isDefault': instance.isDefault,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$AccountTypeEnumMap = {
  AccountType.cash: 'cash',
  AccountType.bank: 'bank',
  AccountType.mfs: 'mfs',
};
