// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BudgetModel _$BudgetModelFromJson(Map<String, dynamic> json) {
  return _BudgetModel.fromJson(json);
}

/// @nodoc
mixin _$BudgetModel {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get categoryId => throw _privateConstructorUsedError;
  @HiveField(2)
  double get amount => throw _privateConstructorUsedError;
  @HiveField(3)
  DateTime get month => throw _privateConstructorUsedError;
  @HiveField(4)
  double get spent => throw _privateConstructorUsedError;
  @HiveField(5)
  bool get rollover => throw _privateConstructorUsedError;
  @HiveField(6)
  double get rolledAmount => throw _privateConstructorUsedError;
  @HiveField(7)
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @HiveField(8)
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BudgetModelCopyWith<BudgetModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BudgetModelCopyWith<$Res> {
  factory $BudgetModelCopyWith(
          BudgetModel value, $Res Function(BudgetModel) then) =
      _$BudgetModelCopyWithImpl<$Res, BudgetModel>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String categoryId,
      @HiveField(2) double amount,
      @HiveField(3) DateTime month,
      @HiveField(4) double spent,
      @HiveField(5) bool rollover,
      @HiveField(6) double rolledAmount,
      @HiveField(7) DateTime? createdAt,
      @HiveField(8) DateTime? updatedAt});
}

/// @nodoc
class _$BudgetModelCopyWithImpl<$Res, $Val extends BudgetModel>
    implements $BudgetModelCopyWith<$Res> {
  _$BudgetModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? categoryId = null,
    Object? amount = null,
    Object? month = null,
    Object? spent = null,
    Object? rollover = null,
    Object? rolledAmount = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      month: null == month
          ? _value.month
          : month // ignore: cast_nullable_to_non_nullable
              as DateTime,
      spent: null == spent
          ? _value.spent
          : spent // ignore: cast_nullable_to_non_nullable
              as double,
      rollover: null == rollover
          ? _value.rollover
          : rollover // ignore: cast_nullable_to_non_nullable
              as bool,
      rolledAmount: null == rolledAmount
          ? _value.rolledAmount
          : rolledAmount // ignore: cast_nullable_to_non_nullable
              as double,
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
abstract class _$$BudgetModelImplCopyWith<$Res>
    implements $BudgetModelCopyWith<$Res> {
  factory _$$BudgetModelImplCopyWith(
          _$BudgetModelImpl value, $Res Function(_$BudgetModelImpl) then) =
      __$$BudgetModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String categoryId,
      @HiveField(2) double amount,
      @HiveField(3) DateTime month,
      @HiveField(4) double spent,
      @HiveField(5) bool rollover,
      @HiveField(6) double rolledAmount,
      @HiveField(7) DateTime? createdAt,
      @HiveField(8) DateTime? updatedAt});
}

/// @nodoc
class __$$BudgetModelImplCopyWithImpl<$Res>
    extends _$BudgetModelCopyWithImpl<$Res, _$BudgetModelImpl>
    implements _$$BudgetModelImplCopyWith<$Res> {
  __$$BudgetModelImplCopyWithImpl(
      _$BudgetModelImpl _value, $Res Function(_$BudgetModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? categoryId = null,
    Object? amount = null,
    Object? month = null,
    Object? spent = null,
    Object? rollover = null,
    Object? rolledAmount = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$BudgetModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      month: null == month
          ? _value.month
          : month // ignore: cast_nullable_to_non_nullable
              as DateTime,
      spent: null == spent
          ? _value.spent
          : spent // ignore: cast_nullable_to_non_nullable
              as double,
      rollover: null == rollover
          ? _value.rollover
          : rollover // ignore: cast_nullable_to_non_nullable
              as bool,
      rolledAmount: null == rolledAmount
          ? _value.rolledAmount
          : rolledAmount // ignore: cast_nullable_to_non_nullable
              as double,
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
class _$BudgetModelImpl implements _BudgetModel {
  const _$BudgetModelImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.categoryId,
      @HiveField(2) required this.amount,
      @HiveField(3) required this.month,
      @HiveField(4) this.spent = 0,
      @HiveField(5) this.rollover = false,
      @HiveField(6) this.rolledAmount = 0,
      @HiveField(7) this.createdAt,
      @HiveField(8) this.updatedAt});

  factory _$BudgetModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$BudgetModelImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String categoryId;
  @override
  @HiveField(2)
  final double amount;
  @override
  @HiveField(3)
  final DateTime month;
  @override
  @JsonKey()
  @HiveField(4)
  final double spent;
  @override
  @JsonKey()
  @HiveField(5)
  final bool rollover;
  @override
  @JsonKey()
  @HiveField(6)
  final double rolledAmount;
  @override
  @HiveField(7)
  final DateTime? createdAt;
  @override
  @HiveField(8)
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'BudgetModel(id: $id, categoryId: $categoryId, amount: $amount, month: $month, spent: $spent, rollover: $rollover, rolledAmount: $rolledAmount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BudgetModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.spent, spent) || other.spent == spent) &&
            (identical(other.rollover, rollover) ||
                other.rollover == rollover) &&
            (identical(other.rolledAmount, rolledAmount) ||
                other.rolledAmount == rolledAmount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, categoryId, amount, month,
      spent, rollover, rolledAmount, createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BudgetModelImplCopyWith<_$BudgetModelImpl> get copyWith =>
      __$$BudgetModelImplCopyWithImpl<_$BudgetModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BudgetModelImplToJson(
      this,
    );
  }
}

abstract class _BudgetModel implements BudgetModel {
  const factory _BudgetModel(
      {@HiveField(0) required final String id,
      @HiveField(1) required final String categoryId,
      @HiveField(2) required final double amount,
      @HiveField(3) required final DateTime month,
      @HiveField(4) final double spent,
      @HiveField(5) final bool rollover,
      @HiveField(6) final double rolledAmount,
      @HiveField(7) final DateTime? createdAt,
      @HiveField(8) final DateTime? updatedAt}) = _$BudgetModelImpl;

  factory _BudgetModel.fromJson(Map<String, dynamic> json) =
      _$BudgetModelImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get categoryId;
  @override
  @HiveField(2)
  double get amount;
  @override
  @HiveField(3)
  DateTime get month;
  @override
  @HiveField(4)
  double get spent;
  @override
  @HiveField(5)
  bool get rollover;
  @override
  @HiveField(6)
  double get rolledAmount;
  @override
  @HiveField(7)
  DateTime? get createdAt;
  @override
  @HiveField(8)
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$BudgetModelImplCopyWith<_$BudgetModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
