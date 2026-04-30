import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'asset_model.freezed.dart';
part 'asset_model.g.dart';

@freezed
@HiveType(typeId: 11)
class AssetModel with _$AssetModel {
  const factory AssetModel({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required double purchasePrice,
    @HiveField(3) required double currentValue,
    @HiveField(4) required DateTime purchaseDate,
    @HiveField(5) DateTime? warrantyExpiry,
    @HiveField(6) DateTime? insuranceExpiry,
    @HiveField(7) String? category,
    @HiveField(8) String? note,
    @HiveField(9) DateTime? createdAt,
    @HiveField(10) DateTime? updatedAt,
  }) = _AssetModel;

  factory AssetModel.fromJson(Map<String, dynamic> json) =>
      _$AssetModelFromJson(json);
}
