// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'split_expense_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SplitGroupAdapter extends TypeAdapter<SplitGroup> {
  @override
  final int typeId = 18;

  @override
  SplitGroup read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SplitGroup(
      id: fields[0] as String,
      name: fields[1] as String,
      members: (fields[2] as List).cast<String>(),
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SplitGroup obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.members)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SplitExpenseAdapter extends TypeAdapter<SplitExpense> {
  @override
  final int typeId = 19;

  @override
  SplitExpense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SplitExpense(
      id: fields[0] as String,
      groupId: fields[1] as String,
      description: fields[2] as String,
      amount: fields[3] as int,
      paidBy: fields[4] as String,
      splitAmong: (fields[5] as List).cast<String>(),
      date: fields[6] as DateTime,
      createdAt: fields[7] as DateTime?,
      updatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SplitExpense obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.paidBy)
      ..writeByte(5)
      ..write(obj.splitAmong)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SplitGroupImpl _$$SplitGroupImplFromJson(Map<String, dynamic> json) =>
    _$SplitGroupImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      members:
          (json['members'] as List<dynamic>).map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$SplitGroupImplToJson(_$SplitGroupImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'members': instance.members,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$SplitExpenseImpl _$$SplitExpenseImplFromJson(Map<String, dynamic> json) =>
    _$SplitExpenseImpl(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toInt(),
      paidBy: json['paidBy'] as String,
      splitAmong: (json['splitAmong'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      date: DateTime.parse(json['date'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$SplitExpenseImplToJson(_$SplitExpenseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'description': instance.description,
      'amount': instance.amount,
      'paidBy': instance.paidBy,
      'splitAmong': instance.splitAmong,
      'date': instance.date.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
