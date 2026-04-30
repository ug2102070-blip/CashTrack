// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'investment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

InvestmentModel _$InvestmentModelFromJson(Map<String, dynamic> json) {
  return _InvestmentModel.fromJson(json);
}

/// @nodoc
mixin _$InvestmentModel {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get name => throw _privateConstructorUsedError;
  @HiveField(2)
  InvestmentType get type => throw _privateConstructorUsedError;
  @HiveField(3)
  double get investedAmount => throw _privateConstructorUsedError;
  @HiveField(4)
  double get currentValue => throw _privateConstructorUsedError;
  @HiveField(5)
  double get expectedReturn => throw _privateConstructorUsedError;
  @HiveField(6)
  DateTime get startDate => throw _privateConstructorUsedError;
  @HiveField(7)
  DateTime? get maturityDate => throw _privateConstructorUsedError;
  @HiveField(8)
  String? get note => throw _privateConstructorUsedError;
  @HiveField(9)
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @HiveField(10)
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $InvestmentModelCopyWith<InvestmentModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvestmentModelCopyWith<$Res> {
  factory $InvestmentModelCopyWith(
          InvestmentModel value, $Res Function(InvestmentModel) then) =
      _$InvestmentModelCopyWithImpl<$Res, InvestmentModel>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String name,
      @HiveField(2) InvestmentType type,
      @HiveField(3) double investedAmount,
      @HiveField(4) double currentValue,
      @HiveField(5) double expectedReturn,
      @HiveField(6) DateTime startDate,
      @HiveField(7) DateTime? maturityDate,
      @HiveField(8) String? note,
      @HiveField(9) DateTime? createdAt,
      @HiveField(10) DateTime? updatedAt});
}

/// @nodoc
class _$InvestmentModelCopyWithImpl<$Res, $Val extends InvestmentModel>
    implements $InvestmentModelCopyWith<$Res> {
  _$InvestmentModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? investedAmount = null,
    Object? currentValue = null,
    Object? expectedReturn = null,
    Object? startDate = null,
    Object? maturityDate = freezed,
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
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as InvestmentType,
      investedAmount: null == investedAmount
          ? _value.investedAmount
          : investedAmount // ignore: cast_nullable_to_non_nullable
              as double,
      currentValue: null == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double,
      expectedReturn: null == expectedReturn
          ? _value.expectedReturn
          : expectedReturn // ignore: cast_nullable_to_non_nullable
              as double,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      maturityDate: freezed == maturityDate
          ? _value.maturityDate
          : maturityDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
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
abstract class _$$InvestmentModelImplCopyWith<$Res>
    implements $InvestmentModelCopyWith<$Res> {
  factory _$$InvestmentModelImplCopyWith(_$InvestmentModelImpl value,
          $Res Function(_$InvestmentModelImpl) then) =
      __$$InvestmentModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String name,
      @HiveField(2) InvestmentType type,
      @HiveField(3) double investedAmount,
      @HiveField(4) double currentValue,
      @HiveField(5) double expectedReturn,
      @HiveField(6) DateTime startDate,
      @HiveField(7) DateTime? maturityDate,
      @HiveField(8) String? note,
      @HiveField(9) DateTime? createdAt,
      @HiveField(10) DateTime? updatedAt});
}

/// @nodoc
class __$$InvestmentModelImplCopyWithImpl<$Res>
    extends _$InvestmentModelCopyWithImpl<$Res, _$InvestmentModelImpl>
    implements _$$InvestmentModelImplCopyWith<$Res> {
  __$$InvestmentModelImplCopyWithImpl(
      _$InvestmentModelImpl _value, $Res Function(_$InvestmentModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? investedAmount = null,
    Object? currentValue = null,
    Object? expectedReturn = null,
    Object? startDate = null,
    Object? maturityDate = freezed,
    Object? note = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$InvestmentModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as InvestmentType,
      investedAmount: null == investedAmount
          ? _value.investedAmount
          : investedAmount // ignore: cast_nullable_to_non_nullable
              as double,
      currentValue: null == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double,
      expectedReturn: null == expectedReturn
          ? _value.expectedReturn
          : expectedReturn // ignore: cast_nullable_to_non_nullable
              as double,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      maturityDate: freezed == maturityDate
          ? _value.maturityDate
          : maturityDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
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
class _$InvestmentModelImpl implements _InvestmentModel {
  const _$InvestmentModelImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.name,
      @HiveField(2) required this.type,
      @HiveField(3) required this.investedAmount,
      @HiveField(4) required this.currentValue,
      @HiveField(5) this.expectedReturn = 0,
      @HiveField(6) required this.startDate,
      @HiveField(7) this.maturityDate,
      @HiveField(8) this.note,
      @HiveField(9) this.createdAt,
      @HiveField(10) this.updatedAt});

  factory _$InvestmentModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$InvestmentModelImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String name;
  @override
  @HiveField(2)
  final InvestmentType type;
  @override
  @HiveField(3)
  final double investedAmount;
  @override
  @HiveField(4)
  final double currentValue;
  @override
  @JsonKey()
  @HiveField(5)
  final double expectedReturn;
  @override
  @HiveField(6)
  final DateTime startDate;
  @override
  @HiveField(7)
  final DateTime? maturityDate;
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
    return 'InvestmentModel(id: $id, name: $name, type: $type, investedAmount: $investedAmount, currentValue: $currentValue, expectedReturn: $expectedReturn, startDate: $startDate, maturityDate: $maturityDate, note: $note, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvestmentModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.investedAmount, investedAmount) ||
                other.investedAmount == investedAmount) &&
            (identical(other.currentValue, currentValue) ||
                other.currentValue == currentValue) &&
            (identical(other.expectedReturn, expectedReturn) ||
                other.expectedReturn == expectedReturn) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.maturityDate, maturityDate) ||
                other.maturityDate == maturityDate) &&
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
      type,
      investedAmount,
      currentValue,
      expectedReturn,
      startDate,
      maturityDate,
      note,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InvestmentModelImplCopyWith<_$InvestmentModelImpl> get copyWith =>
      __$$InvestmentModelImplCopyWithImpl<_$InvestmentModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InvestmentModelImplToJson(
      this,
    );
  }
}

abstract class _InvestmentModel implements InvestmentModel {
  const factory _InvestmentModel(
      {@HiveField(0) required final String id,
      @HiveField(1) required final String name,
      @HiveField(2) required final InvestmentType type,
      @HiveField(3) required final double investedAmount,
      @HiveField(4) required final double currentValue,
      @HiveField(5) final double expectedReturn,
      @HiveField(6) required final DateTime startDate,
      @HiveField(7) final DateTime? maturityDate,
      @HiveField(8) final String? note,
      @HiveField(9) final DateTime? createdAt,
      @HiveField(10) final DateTime? updatedAt}) = _$InvestmentModelImpl;

  factory _InvestmentModel.fromJson(Map<String, dynamic> json) =
      _$InvestmentModelImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get name;
  @override
  @HiveField(2)
  InvestmentType get type;
  @override
  @HiveField(3)
  double get investedAmount;
  @override
  @HiveField(4)
  double get currentValue;
  @override
  @HiveField(5)
  double get expectedReturn;
  @override
  @HiveField(6)
  DateTime get startDate;
  @override
  @HiveField(7)
  DateTime? get maturityDate;
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
  _$$InvestmentModelImplCopyWith<_$InvestmentModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
