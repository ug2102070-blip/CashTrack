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
      phoneNumber: fields[10] as String?,
      agreementStatus: fields[11] as AgreementStatus,
      penaltyRate: fields[12] as double,
      penaltyAmount: fields[13] as double,
      agreementTerms: fields[14] as String?,
      trustScore: fields[15] as int,
      remindersSent: fields[16] as int,
      lastReminderAt: fields[17] as DateTime?,
      hasAgreement: fields[18] as bool,
      paymentMethod: fields[19] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DebtModel obj) {
    writer
      ..writeByte(20)
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
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.phoneNumber)
      ..writeByte(11)
      ..write(obj.agreementStatus)
      ..writeByte(12)
      ..write(obj.penaltyRate)
      ..writeByte(13)
      ..write(obj.penaltyAmount)
      ..writeByte(14)
      ..write(obj.agreementTerms)
      ..writeByte(15)
      ..write(obj.trustScore)
      ..writeByte(16)
      ..write(obj.remindersSent)
      ..writeByte(17)
      ..write(obj.lastReminderAt)
      ..writeByte(18)
      ..write(obj.hasAgreement)
      ..writeByte(19)
      ..write(obj.paymentMethod);
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

class AgreementStatusAdapter extends TypeAdapter<AgreementStatus> {
  @override
  final int typeId = 17;

  @override
  AgreementStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AgreementStatus.pending;
      case 1:
        return AgreementStatus.accepted;
      case 2:
        return AgreementStatus.rejected;
      case 3:
        return AgreementStatus.expired;
      case 4:
        return AgreementStatus.completed;
      default:
        return AgreementStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, AgreementStatus obj) {
    switch (obj) {
      case AgreementStatus.pending:
        writer.writeByte(0);
        break;
      case AgreementStatus.accepted:
        writer.writeByte(1);
        break;
      case AgreementStatus.rejected:
        writer.writeByte(2);
        break;
      case AgreementStatus.expired:
        writer.writeByte(3);
        break;
      case AgreementStatus.completed:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgreementStatusAdapter &&
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
      phoneNumber: json['phoneNumber'] as String?,
      agreementStatus: $enumDecodeNullable(
              _$AgreementStatusEnumMap, json['agreementStatus']) ??
          AgreementStatus.pending,
      penaltyRate: (json['penaltyRate'] as num?)?.toDouble() ?? 0,
      penaltyAmount: (json['penaltyAmount'] as num?)?.toDouble() ?? 0,
      agreementTerms: json['agreementTerms'] as String?,
      trustScore: (json['trustScore'] as num?)?.toInt() ?? 100,
      remindersSent: (json['remindersSent'] as num?)?.toInt() ?? 0,
      lastReminderAt: json['lastReminderAt'] == null
          ? null
          : DateTime.parse(json['lastReminderAt'] as String),
      hasAgreement: json['hasAgreement'] as bool? ?? false,
      paymentMethod: json['paymentMethod'] as String?,
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
      'phoneNumber': instance.phoneNumber,
      'agreementStatus': _$AgreementStatusEnumMap[instance.agreementStatus]!,
      'penaltyRate': instance.penaltyRate,
      'penaltyAmount': instance.penaltyAmount,
      'agreementTerms': instance.agreementTerms,
      'trustScore': instance.trustScore,
      'remindersSent': instance.remindersSent,
      'lastReminderAt': instance.lastReminderAt?.toIso8601String(),
      'hasAgreement': instance.hasAgreement,
      'paymentMethod': instance.paymentMethod,
    };

const _$DebtTypeEnumMap = {
  DebtType.lent: 'lent',
  DebtType.borrowed: 'borrowed',
};

const _$AgreementStatusEnumMap = {
  AgreementStatus.pending: 'pending',
  AgreementStatus.accepted: 'accepted',
  AgreementStatus.rejected: 'rejected',
  AgreementStatus.expired: 'expired',
  AgreementStatus.completed: 'completed',
};
