// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 0;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionModel(
      id: fields[0] as String,
      type: fields[1] as TransactionType,
      amount: fields[2] as double,
      categoryId: fields[3] as String,
      accountId: fields[4] as String,
      date: fields[5] as DateTime,
      note: fields[6] as String?,
      receiptUrl: fields[7] as String?,
      isRecurring: fields[8] as bool,
      recurringType: fields[9] as RecurringType?,
      isSynced: fields[10] as bool,
      isDeleted: fields[11] as bool,
      createdAt: fields[12] as DateTime?,
      updatedAt: fields[13] as DateTime?,
      smsId: fields[14] as String?,
      toAccountId: fields[15] as String?,
      tags: (fields[16] as List).cast<String>(),
      confidenceScore: fields[17] as double,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.accountId)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.receiptUrl)
      ..writeByte(8)
      ..write(obj.isRecurring)
      ..writeByte(9)
      ..write(obj.recurringType)
      ..writeByte(10)
      ..write(obj.isSynced)
      ..writeByte(11)
      ..write(obj.isDeleted)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.smsId)
      ..writeByte(15)
      ..write(obj.toAccountId)
      ..writeByte(16)
      ..write(obj.tags)
      ..writeByte(17)
      ..write(obj.confidenceScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = 1;

  @override
  TransactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionType.income;
      case 1:
        return TransactionType.expense;
      case 2:
        return TransactionType.transfer;
      case 3:
        return TransactionType.lent;
      case 4:
        return TransactionType.borrowed;
      default:
        return TransactionType.income;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    switch (obj) {
      case TransactionType.income:
        writer.writeByte(0);
        break;
      case TransactionType.expense:
        writer.writeByte(1);
        break;
      case TransactionType.transfer:
        writer.writeByte(2);
        break;
      case TransactionType.lent:
        writer.writeByte(3);
        break;
      case TransactionType.borrowed:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurringTypeAdapter extends TypeAdapter<RecurringType> {
  @override
  final int typeId = 2;

  @override
  RecurringType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurringType.daily;
      case 1:
        return RecurringType.weekly;
      case 2:
        return RecurringType.monthly;
      case 3:
        return RecurringType.yearly;
      default:
        return RecurringType.daily;
    }
  }

  @override
  void write(BinaryWriter writer, RecurringType obj) {
    switch (obj) {
      case RecurringType.daily:
        writer.writeByte(0);
        break;
      case RecurringType.weekly:
        writer.writeByte(1);
        break;
      case RecurringType.monthly:
        writer.writeByte(2);
        break;
      case RecurringType.yearly:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionModelImpl _$$TransactionModelImplFromJson(
        Map<String, dynamic> json) =>
    _$TransactionModelImpl(
      id: json['id'] as String,
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'] as String,
      accountId: json['accountId'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringType:
          $enumDecodeNullable(_$RecurringTypeEnumMap, json['recurringType']),
      isSynced: json['isSynced'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      smsId: json['smsId'] as String?,
      toAccountId: json['toAccountId'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$TransactionModelImplToJson(
        _$TransactionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'amount': instance.amount,
      'categoryId': instance.categoryId,
      'accountId': instance.accountId,
      'date': instance.date.toIso8601String(),
      'note': instance.note,
      'receiptUrl': instance.receiptUrl,
      'isRecurring': instance.isRecurring,
      'recurringType': _$RecurringTypeEnumMap[instance.recurringType],
      'isSynced': instance.isSynced,
      'isDeleted': instance.isDeleted,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'smsId': instance.smsId,
      'toAccountId': instance.toAccountId,
      'tags': instance.tags,
      'confidenceScore': instance.confidenceScore,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.income: 'income',
  TransactionType.expense: 'expense',
  TransactionType.transfer: 'transfer',
  TransactionType.lent: 'lent',
  TransactionType.borrowed: 'borrowed',
};

const _$RecurringTypeEnumMap = {
  RecurringType.daily: 'daily',
  RecurringType.weekly: 'weekly',
  RecurringType.monthly: 'monthly',
  RecurringType.yearly: 'yearly',
};
