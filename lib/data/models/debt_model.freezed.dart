// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'debt_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DebtModel _$DebtModelFromJson(Map<String, dynamic> json) {
  return _DebtModel.fromJson(json);
}

/// @nodoc
mixin _$DebtModel {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  DebtType get type => throw _privateConstructorUsedError;
  @HiveField(2)
  String get personName => throw _privateConstructorUsedError;
  @HiveField(3)
  double get amount => throw _privateConstructorUsedError;
  @HiveField(4)
  double get paidAmount => throw _privateConstructorUsedError;
  @HiveField(5)
  DateTime? get dueDate => throw _privateConstructorUsedError;
  @HiveField(6)
  String? get note => throw _privateConstructorUsedError;
  @HiveField(7)
  bool get isSettled => throw _privateConstructorUsedError;
  @HiveField(8)
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @HiveField(9)
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DebtModelCopyWith<DebtModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DebtModelCopyWith<$Res> {
  factory $DebtModelCopyWith(DebtModel value, $Res Function(DebtModel) then) =
      _$DebtModelCopyWithImpl<$Res, DebtModel>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) DebtType type,
      @HiveField(2) String personName,
      @HiveField(3) double amount,
      @HiveField(4) double paidAmount,
      @HiveField(5) DateTime? dueDate,
      @HiveField(6) String? note,
      @HiveField(7) bool isSettled,
      @HiveField(8) DateTime? createdAt,
      @HiveField(9) DateTime? updatedAt});
}

/// @nodoc
class _$DebtModelCopyWithImpl<$Res, $Val extends DebtModel>
    implements $DebtModelCopyWith<$Res> {
  _$DebtModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? personName = null,
    Object? amount = null,
    Object? paidAmount = null,
    Object? dueDate = freezed,
    Object? note = freezed,
    Object? isSettled = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as DebtType,
      personName: null == personName
          ? _value.personName
          : personName // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      paidAmount: null == paidAmount
          ? _value.paidAmount
          : paidAmount // ignore: cast_nullable_to_non_nullable
              as double,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      isSettled: null == isSettled
          ? _value.isSettled
          : isSettled // ignore: cast_nullable_to_non_nullable
              as bool,
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
abstract class _$$DebtModelImplCopyWith<$Res>
    implements $DebtModelCopyWith<$Res> {
  factory _$$DebtModelImplCopyWith(
          _$DebtModelImpl value, $Res Function(_$DebtModelImpl) then) =
      __$$DebtModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) DebtType type,
      @HiveField(2) String personName,
      @HiveField(3) double amount,
      @HiveField(4) double paidAmount,
      @HiveField(5) DateTime? dueDate,
      @HiveField(6) String? note,
      @HiveField(7) bool isSettled,
      @HiveField(8) DateTime? createdAt,
      @HiveField(9) DateTime? updatedAt});
}

/// @nodoc
class __$$DebtModelImplCopyWithImpl<$Res>
    extends _$DebtModelCopyWithImpl<$Res, _$DebtModelImpl>
    implements _$$DebtModelImplCopyWith<$Res> {
  __$$DebtModelImplCopyWithImpl(
      _$DebtModelImpl _value, $Res Function(_$DebtModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? personName = null,
    Object? amount = null,
    Object? paidAmount = null,
    Object? dueDate = freezed,
    Object? note = freezed,
    Object? isSettled = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$DebtModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as DebtType,
      personName: null == personName
          ? _value.personName
          : personName // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      paidAmount: null == paidAmount
          ? _value.paidAmount
          : paidAmount // ignore: cast_nullable_to_non_nullable
              as double,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      isSettled: null == isSettled
          ? _value.isSettled
          : isSettled // ignore: cast_nullable_to_non_nullable
              as bool,
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
class _$DebtModelImpl implements _DebtModel {
  const _$DebtModelImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.type,
      @HiveField(2) required this.personName,
      @HiveField(3) required this.amount,
      @HiveField(4) this.paidAmount = 0,
      @HiveField(5) this.dueDate,
      @HiveField(6) this.note,
      @HiveField(7) this.isSettled = false,
      @HiveField(8) this.createdAt,
      @HiveField(9) this.updatedAt});

  factory _$DebtModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DebtModelImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final DebtType type;
  @override
  @HiveField(2)
  final String personName;
  @override
  @HiveField(3)
  final double amount;
  @override
  @JsonKey()
  @HiveField(4)
  final double paidAmount;
  @override
  @HiveField(5)
  final DateTime? dueDate;
  @override
  @HiveField(6)
  final String? note;
  @override
  @JsonKey()
  @HiveField(7)
  final bool isSettled;
  @override
  @HiveField(8)
  final DateTime? createdAt;
  @override
  @HiveField(9)
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'DebtModel(id: $id, type: $type, personName: $personName, amount: $amount, paidAmount: $paidAmount, dueDate: $dueDate, note: $note, isSettled: $isSettled, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DebtModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.personName, personName) ||
                other.personName == personName) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.paidAmount, paidAmount) ||
                other.paidAmount == paidAmount) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.isSettled, isSettled) ||
                other.isSettled == isSettled) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, type, personName, amount,
      paidAmount, dueDate, note, isSettled, createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DebtModelImplCopyWith<_$DebtModelImpl> get copyWith =>
      __$$DebtModelImplCopyWithImpl<_$DebtModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DebtModelImplToJson(
      this,
    );
  }
}

abstract class _DebtModel implements DebtModel {
  const factory _DebtModel(
      {@HiveField(0) required final String id,
      @HiveField(1) required final DebtType type,
      @HiveField(2) required final String personName,
      @HiveField(3) required final double amount,
      @HiveField(4) final double paidAmount,
      @HiveField(5) final DateTime? dueDate,
      @HiveField(6) final String? note,
      @HiveField(7) final bool isSettled,
      @HiveField(8) final DateTime? createdAt,
      @HiveField(9) final DateTime? updatedAt}) = _$DebtModelImpl;

  factory _DebtModel.fromJson(Map<String, dynamic> json) =
      _$DebtModelImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  DebtType get type;
  @override
  @HiveField(2)
  String get personName;
  @override
  @HiveField(3)
  double get amount;
  @override
  @HiveField(4)
  double get paidAmount;
  @override
  @HiveField(5)
  DateTime? get dueDate;
  @override
  @HiveField(6)
  String? get note;
  @override
  @HiveField(7)
  bool get isSettled;
  @override
  @HiveField(8)
  DateTime? get createdAt;
  @override
  @HiveField(9)
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$DebtModelImplCopyWith<_$DebtModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
