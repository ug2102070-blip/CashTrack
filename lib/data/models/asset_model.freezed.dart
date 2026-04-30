// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AssetModel _$AssetModelFromJson(Map<String, dynamic> json) {
  return _AssetModel.fromJson(json);
}

/// @nodoc
mixin _$AssetModel {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get name => throw _privateConstructorUsedError;
  @HiveField(2)
  double get purchasePrice => throw _privateConstructorUsedError;
  @HiveField(3)
  double get currentValue => throw _privateConstructorUsedError;
  @HiveField(4)
  DateTime get purchaseDate => throw _privateConstructorUsedError;
  @HiveField(5)
  DateTime? get warrantyExpiry => throw _privateConstructorUsedError;
  @HiveField(6)
  DateTime? get insuranceExpiry => throw _privateConstructorUsedError;
  @HiveField(7)
  String? get category => throw _privateConstructorUsedError;
  @HiveField(8)
  String? get note => throw _privateConstructorUsedError;
  @HiveField(9)
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @HiveField(10)
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AssetModelCopyWith<AssetModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AssetModelCopyWith<$Res> {
  factory $AssetModelCopyWith(
          AssetModel value, $Res Function(AssetModel) then) =
      _$AssetModelCopyWithImpl<$Res, AssetModel>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String name,
      @HiveField(2) double purchasePrice,
      @HiveField(3) double currentValue,
      @HiveField(4) DateTime purchaseDate,
      @HiveField(5) DateTime? warrantyExpiry,
      @HiveField(6) DateTime? insuranceExpiry,
      @HiveField(7) String? category,
      @HiveField(8) String? note,
      @HiveField(9) DateTime? createdAt,
      @HiveField(10) DateTime? updatedAt});
}

/// @nodoc
class _$AssetModelCopyWithImpl<$Res, $Val extends AssetModel>
    implements $AssetModelCopyWith<$Res> {
  _$AssetModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? purchasePrice = null,
    Object? currentValue = null,
    Object? purchaseDate = null,
    Object? warrantyExpiry = freezed,
    Object? insuranceExpiry = freezed,
    Object? category = freezed,
    Object? note = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      purchasePrice: null == purchasePrice
          ? _value.purchasePrice
          : purchasePrice // ignore: cast_nullable_to_non_nullable
              as double,
      currentValue: null == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double,
      purchaseDate: null == purchaseDate
          ? _value.purchaseDate
          : purchaseDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      warrantyExpiry: freezed == warrantyExpiry
          ? _value.warrantyExpiry
          : warrantyExpiry // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      insuranceExpiry: freezed == insuranceExpiry
          ? _value.insuranceExpiry
          : insuranceExpiry // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AssetModelImplCopyWith<$Res>
    implements $AssetModelCopyWith<$Res> {
  factory _$$AssetModelImplCopyWith(
          _$AssetModelImpl value, $Res Function(_$AssetModelImpl) then) =
      __$$AssetModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String name,
      @HiveField(2) double purchasePrice,
      @HiveField(3) double currentValue,
      @HiveField(4) DateTime purchaseDate,
      @HiveField(5) DateTime? warrantyExpiry,
      @HiveField(6) DateTime? insuranceExpiry,
      @HiveField(7) String? category,
      @HiveField(8) String? note,
      @HiveField(9) DateTime? createdAt,
      @HiveField(10) DateTime? updatedAt});
}

/// @nodoc
class __$$AssetModelImplCopyWithImpl<$Res>
    extends _$AssetModelCopyWithImpl<$Res, _$AssetModelImpl>
    implements _$$AssetModelImplCopyWith<$Res> {
  __$$AssetModelImplCopyWithImpl(
      _$AssetModelImpl _value, $Res Function(_$AssetModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? purchasePrice = null,
    Object? currentValue = null,
    Object? purchaseDate = null,
    Object? warrantyExpiry = freezed,
    Object? insuranceExpiry = freezed,
    Object? category = freezed,
    Object? note = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$AssetModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      purchasePrice: null == purchasePrice
          ? _value.purchasePrice
          : purchasePrice // ignore: cast_nullable_to_non_nullable
              as double,
      currentValue: null == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double,
      purchaseDate: null == purchaseDate
          ? _value.purchaseDate
          : purchaseDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      warrantyExpiry: freezed == warrantyExpiry
          ? _value.warrantyExpiry
          : warrantyExpiry // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      insuranceExpiry: freezed == insuranceExpiry
          ? _value.insuranceExpiry
          : insuranceExpiry // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AssetModelImpl implements _AssetModel {
  const _$AssetModelImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.name,
      @HiveField(2) required this.purchasePrice,
      @HiveField(3) required this.currentValue,
      @HiveField(4) required this.purchaseDate,
      @HiveField(5) this.warrantyExpiry,
      @HiveField(6) this.insuranceExpiry,
      @HiveField(7) this.category,
      @HiveField(8) this.note,
      @HiveField(9) this.createdAt,
      @HiveField(10) this.updatedAt});

  factory _$AssetModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AssetModelImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String name;
  @override
  @HiveField(2)
  final double purchasePrice;
  @override
  @HiveField(3)
  final double currentValue;
  @override
  @HiveField(4)
  final DateTime purchaseDate;
  @override
  @HiveField(5)
  final DateTime? warrantyExpiry;
  @override
  @HiveField(6)
  final DateTime? insuranceExpiry;
  @override
  @HiveField(7)
  final String? category;
  @override
  @HiveField(8)
  final String? note;
  @override
  @HiveField(9)
  final DateTime? createdAt;
  @override
  @HiveField(10)
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'AssetModel(id: $id, name: $name, purchasePrice: $purchasePrice, currentValue: $currentValue, purchaseDate: $purchaseDate, warrantyExpiry: $warrantyExpiry, insuranceExpiry: $insuranceExpiry, category: $category, note: $note, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AssetModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.purchasePrice, purchasePrice) ||
                other.purchasePrice == purchasePrice) &&
            (identical(other.currentValue, currentValue) ||
                other.currentValue == currentValue) &&
            (identical(other.purchaseDate, purchaseDate) ||
                other.purchaseDate == purchaseDate) &&
            (identical(other.warrantyExpiry, warrantyExpiry) ||
                other.warrantyExpiry == warrantyExpiry) &&
            (identical(other.insuranceExpiry, insuranceExpiry) ||
                other.insuranceExpiry == insuranceExpiry) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      purchasePrice,
      currentValue,
      purchaseDate,
      warrantyExpiry,
      insuranceExpiry,
      category,
      note,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AssetModelImplCopyWith<_$AssetModelImpl> get copyWith =>
      __$$AssetModelImplCopyWithImpl<_$AssetModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AssetModelImplToJson(
      this,
    );
  }
}

abstract class _AssetModel implements AssetModel {
  const factory _AssetModel(
      {@HiveField(0) required final String id,
      @HiveField(1) required final String name,
      @HiveField(2) required final double purchasePrice,
      @HiveField(3) required final double currentValue,
      @HiveField(4) required final DateTime purchaseDate,
      @HiveField(5) final DateTime? warrantyExpiry,
      @HiveField(6) final DateTime? insuranceExpiry,
      @HiveField(7) final String? category,
      @HiveField(8) final String? note,
      @HiveField(9) final DateTime? createdAt,
      @HiveField(10) final DateTime? updatedAt}) = _$AssetModelImpl;

  factory _AssetModel.fromJson(Map<String, dynamic> json) =
      _$AssetModelImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get name;
  @override
  @HiveField(2)
  double get purchasePrice;
  @override
  @HiveField(3)
  double get currentValue;
  @override
  @HiveField(4)
  DateTime get purchaseDate;
  @override
  @HiveField(5)
  DateTime? get warrantyExpiry;
  @override
  @HiveField(6)
  DateTime? get insuranceExpiry;
  @override
  @HiveField(7)
  String? get category;
  @override
  @HiveField(8)
  String? get note;
  @override
  @HiveField(9)
  DateTime? get createdAt;
  @override
  @HiveField(10)
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$AssetModelImplCopyWith<_$AssetModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
