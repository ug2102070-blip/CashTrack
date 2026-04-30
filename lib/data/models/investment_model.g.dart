// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvestmentModelAdapter extends TypeAdapter<InvestmentModel> {
  @override
  final int typeId = 12;

  @override
  InvestmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvestmentModel(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as InvestmentType,
      investedAmount: fields[3] as double,
      currentValue: fields[4] as double,
      expectedReturn: fields[5] as double,
      startDate: fields[6] as DateTime,
      maturityDate: fields[7] as DateTime?,
      note: fields[8] as String?,
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, InvestmentModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.investedAmount)
      ..writeByte(4)
      ..write(obj.currentValue)
      ..writeByte(5)
      ..write(obj.expectedReturn)
      ..writeByte(6)
      ..write(obj.startDate)
      ..writeByte(7)
      ..write(obj.maturityDate)
      ..writeByte(8)
      ..write(obj.note)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvestmentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InvestmentTypeAdapter extends TypeAdapter<InvestmentType> {
  @override
  final int typeId = 13;

  @override
  InvestmentType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InvestmentType.mutualFund;
      case 1:
        return InvestmentType.stock;
      case 2:
        return InvestmentType.fixedDeposit;
      case 3:
        return InvestmentType.gold;
      case 4:
        return InvestmentType.dps;
      case 5:
        return InvestmentType.others;
      default:
        return InvestmentType.mutualFund;
    }
  }

  @override
  void write(BinaryWriter writer, InvestmentType obj) {
    switch (obj) {
      case InvestmentType.mutualFund:
        writer.writeByte(0);
        break;
      case InvestmentType.stock:
        writer.writeByte(1);
        break;
      case InvestmentType.fixedDeposit:
        writer.writeByte(2);
        break;
      case InvestmentType.gold:
        writer.writeByte(3);
        break;
      case InvestmentType.dps:
        writer.writeByte(4);
        break;
      case InvestmentType.others:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvestmentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InvestmentModelImpl _$$InvestmentModelImplFromJson(
        Map<String, dynamic> json) =>
    _$InvestmentModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$InvestmentTypeEnumMap, json['type']),
      investedAmount: (json['investedAmount'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
      expectedReturn: (json['expectedReturn'] as num?)?.toDouble() ?? 0,
      startDate: DateTime.parse(json['startDate'] as String),
      maturityDate: json['maturityDate'] == null
          ? null
          : DateTime.parse(json['maturityDate'] as String),
      note: json['note'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$InvestmentModelImplToJson(
        _$InvestmentModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$InvestmentTypeEnumMap[instance.type]!,
      'investedAmount': instance.investedAmount,
      'currentValue': instance.currentValue,
      'expectedReturn': instance.expectedReturn,
      'startDate': instance.startDate.toIso8601String(),
      'maturityDate': instance.maturityDate?.toIso8601String(),
      'note': instance.note,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$InvestmentTypeEnumMap = {
  InvestmentType.mutualFund: 'mutualFund',
  InvestmentType.stock: 'stock',
  InvestmentType.fixedDeposit: 'fixedDeposit',
  InvestmentType.gold: 'gold',
  InvestmentType.dps: 'dps',
  InvestmentType.others: 'others',
};
