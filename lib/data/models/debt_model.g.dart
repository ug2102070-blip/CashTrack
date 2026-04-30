// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DebtModelAdapter extends TypeAdapter<DebtModel> {
  @override
  final int typeId = 9;

  @override
  DebtModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DebtModel(
      id: fields[0] as String,
      type: fields[1] as DebtType,
      personName: fields[2] as String,
      amount: fields[3] as double,
      paidAmount: fields[4] as double,
      dueDate: fields[5] as DateTime?,
      note: fields[6] as String?,
      isSettled: fields[7] as bool,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DebtModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.personName)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.paidAmount)
      ..writeByte(5)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.isSettled)
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
      other is DebtModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DebtTypeAdapter extends TypeAdapter<DebtType> {
  @override
  final int typeId = 10;

  @override
  DebtType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DebtType.lent;
      case 1:
        return DebtType.borrowed;
      default:
        return DebtType.lent;
    }
  }

  @override
  void write(BinaryWriter writer, DebtType obj) {
    switch (obj) {
      case DebtType.lent:
        writer.writeByte(0);
        break;
      case DebtType.borrowed:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DebtModelImpl _$$DebtModelImplFromJson(Map<String, dynamic> json) =>
    _$DebtModelImpl(
      id: json['id'] as String,
      type: $enumDecode(_$DebtTypeEnumMap, json['type']),
      personName: json['personName'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      note: json['note'] as String?,
      isSettled: json['isSettled'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$DebtModelImplToJson(_$DebtModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$DebtTypeEnumMap[instance.type]!,
      'personName': instance.personName,
      'amount': instance.amount,
      'paidAmount': instance.paidAmount,
      'dueDate': instance.dueDate?.toIso8601String(),
      'note': instance.note,
      'isSettled': instance.isSettled,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$DebtTypeEnumMap = {
  DebtType.lent: 'lent',
  DebtType.borrowed: 'borrowed',
};
