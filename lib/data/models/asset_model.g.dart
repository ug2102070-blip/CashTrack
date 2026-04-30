// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssetModelAdapter extends TypeAdapter<AssetModel> {
  @override
  final int typeId = 11;

  @override
  AssetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssetModel(
      id: fields[0] as String,
      name: fields[1] as String,
      purchasePrice: fields[2] as double,
      currentValue: fields[3] as double,
      purchaseDate: fields[4] as DateTime,
      warrantyExpiry: fields[5] as DateTime?,
      insuranceExpiry: fields[6] as DateTime?,
      category: fields[7] as String?,
      note: fields[8] as String?,
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AssetModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.purchasePrice)
      ..writeByte(3)
      ..write(obj.currentValue)
      ..writeByte(4)
      ..write(obj.purchaseDate)
      ..writeByte(5)
      ..write(obj.warrantyExpiry)
      ..writeByte(6)
      ..write(obj.insuranceExpiry)
      ..writeByte(7)
      ..write(obj.category)
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
      other is AssetModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AssetModelImpl _$$AssetModelImplFromJson(Map<String, dynamic> json) =>
    _$AssetModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      warrantyExpiry: json['warrantyExpiry'] == null
          ? null
          : DateTime.parse(json['warrantyExpiry'] as String),
      insuranceExpiry: json['insuranceExpiry'] == null
          ? null
          : DateTime.parse(json['insuranceExpiry'] as String),
      category: json['category'] as String?,
      note: json['note'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$AssetModelImplToJson(_$AssetModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'purchasePrice': instance.purchasePrice,
      'currentValue': instance.currentValue,
      'purchaseDate': instance.purchaseDate.toIso8601String(),
      'warrantyExpiry': instance.warrantyExpiry?.toIso8601String(),
      'insuranceExpiry': instance.insuranceExpiry?.toIso8601String(),
      'category': instance.category,
      'note': instance.note,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
