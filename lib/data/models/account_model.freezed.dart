// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AccountModel _$AccountModelFromJson(Map<String, dynamic> json) {
  return _AccountModel.fromJson(json);
}

/// @nodoc
mixin _$AccountModel {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get name => throw _privateConstructorUsedError;
  @HiveField(2)
  String get nameBn => throw _privateConstructorUsedError;
  @HiveField(3)
  AccountType get type => throw _privateConstructorUsedError;
  @HiveField(4)
  double get balance => throw _privateConstructorUsedError;
  @HiveField(5)
  String? get icon => throw _privateConstructorUsedError;
  @HiveField(6)
  String? get colorHex => throw _privateConstructorUsedError;
  @HiveField(7)
  bool get isDefault => throw _privateConstructorUsedError;
  @HiveField(8)
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @HiveField(9)
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @HiveField(10)
  String? get nickname =>
      throw _privateConstructorUsedError; // User-editable custom name (e.g. "Salary Account")
  @HiveField(11)
  String? get userId => throw _privateConstructorUsedError;
  @HiveField(12)
  String? get accountNumber => throw _privateConstructorUsedError;
  @HiveField(13)
  String? get cardType => throw _privateConstructorUsedError;
  @HiveField(14)
  String? get cardIssuer => throw _privateConstructorUsedError;
  @HiveField(15)
  String? get cardholderName => throw _privateConstructorUsedError;
  @HiveField(16)
  double? get creditLimit => throw _privateConstructorUsedError;
  @HiveField(17)
  int? get billingDay => throw _privateConstructorUsedError;
  @HiveField(18)
  int? get paymentDueDay => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AccountModelCopyWith<AccountModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountModelCopyWith<$Res> {
  factory $AccountModelCopyWith(
          AccountModel value, $Res Function(AccountModel) then) =
      _$AccountModelCopyWithImpl<$Res, AccountModel>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String name,
      @HiveField(2) String nameBn,
      @HiveField(3) AccountType type,
      @HiveField(4) double balance,
      @HiveField(5) String? icon,
      @HiveField(6) String? colorHex,
      @HiveField(7) bool isDefault,
      @HiveField(8) DateTime? createdAt,
      @HiveField(9) DateTime? updatedAt,
      @HiveField(10) String? nickname,
      @HiveField(11) String? userId,
      @HiveField(12) String? accountNumber,
      @HiveField(13) String? cardType,
      @HiveField(14) String? cardIssuer,
      @HiveField(15) String? cardholderName,
      @HiveField(16) double? creditLimit,
      @HiveField(17) int? billingDay,
      @HiveField(18) int? paymentDueDay});
}

/// @nodoc
class _$AccountModelCopyWithImpl<$Res, $Val extends AccountModel>
    implements $AccountModelCopyWith<$Res> {
  _$AccountModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? nameBn = null,
    Object? type = null,
    Object? balance = null,
    Object? icon = freezed,
    Object? colorHex = freezed,
    Object? isDefault = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? nickname = freezed,
    Object? userId = freezed,
    Object? accountNumber = freezed,
    Object? cardType = freezed,
    Object? cardIssuer = freezed,
    Object? cardholderName = freezed,
    Object? creditLimit = freezed,
    Object? billingDay = freezed,
    Object? paymentDueDay = freezed,
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
      nameBn: null == nameBn
          ? _value.nameBn
          : nameBn // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as AccountType,
      balance: null == balance
          ? _value.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as double,
      icon: freezed == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String?,
      colorHex: freezed == colorHex
          ? _value.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as String?,
      isDefault: null == isDefault
          ? _value.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nickname: freezed == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String?,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      accountNumber: freezed == accountNumber
          ? _value.accountNumber
          : accountNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      cardType: freezed == cardType
          ? _value.cardType
          : cardType // ignore: cast_nullable_to_non_nullable
              as String?,
      cardIssuer: freezed == cardIssuer
          ? _value.cardIssuer
          : cardIssuer // ignore: cast_nullable_to_non_nullable
              as String?,
      cardholderName: freezed == cardholderName
          ? _value.cardholderName
          : cardholderName // ignore: cast_nullable_to_non_nullable
              as String?,
      creditLimit: freezed == creditLimit
          ? _value.creditLimit
          : creditLimit // ignore: cast_nullable_to_non_nullable
              as double?,
      billingDay: freezed == billingDay
          ? _value.billingDay
          : billingDay // ignore: cast_nullable_to_non_nullable
              as int?,
      paymentDueDay: freezed == paymentDueDay
          ? _value.paymentDueDay
          : paymentDueDay // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AccountModelImplCopyWith<$Res>
    implements $AccountModelCopyWith<$Res> {
  factory _$$AccountModelImplCopyWith(
          _$AccountModelImpl value, $Res Function(_$AccountModelImpl) then) =
      __$$AccountModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String name,
      @HiveField(2) String nameBn,
      @HiveField(3) AccountType type,
      @HiveField(4) double balance,
      @HiveField(5) String? icon,
      @HiveField(6) String? colorHex,
      @HiveField(7) bool isDefault,
      @HiveField(8) DateTime? createdAt,
      @HiveField(9) DateTime? updatedAt,
      @HiveField(10) String? nickname,
      @HiveField(11) String? userId,
      @HiveField(12) String? accountNumber,
      @HiveField(13) String? cardType,
      @HiveField(14) String? cardIssuer,
      @HiveField(15) String? cardholderName,
      @HiveField(16) double? creditLimit,
      @HiveField(17) int? billingDay,
      @HiveField(18) int? paymentDueDay});
}

/// @nodoc
class __$$AccountModelImplCopyWithImpl<$Res>
    extends _$AccountModelCopyWithImpl<$Res, _$AccountModelImpl>
    implements _$$AccountModelImplCopyWith<$Res> {
  __$$AccountModelImplCopyWithImpl(
      _$AccountModelImpl _value, $Res Function(_$AccountModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? nameBn = null,
    Object? type = null,
    Object? balance = null,
    Object? icon = freezed,
    Object? colorHex = freezed,
    Object? isDefault = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? nickname = freezed,
    Object? userId = freezed,
    Object? accountNumber = freezed,
    Object? cardType = freezed,
    Object? cardIssuer = freezed,
    Object? cardholderName = freezed,
    Object? creditLimit = freezed,
    Object? billingDay = freezed,
    Object? paymentDueDay = freezed,
  }) {
    return _then(_$AccountModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      nameBn: null == nameBn
          ? _value.nameBn
          : nameBn // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as AccountType,
      balance: null == balance
          ? _value.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as double,
      icon: freezed == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String?,
      colorHex: freezed == colorHex
          ? _value.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as String?,
      isDefault: null == isDefault
          ? _value.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nickname: freezed == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String?,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      accountNumber: freezed == accountNumber
          ? _value.accountNumber
          : accountNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      cardType: freezed == cardType
          ? _value.cardType
          : cardType // ignore: cast_nullable_to_non_nullable
              as String?,
      cardIssuer: freezed == cardIssuer
          ? _value.cardIssuer
          : cardIssuer // ignore: cast_nullable_to_non_nullable
              as String?,
      cardholderName: freezed == cardholderName
          ? _value.cardholderName
          : cardholderName // ignore: cast_nullable_to_non_nullable
              as String?,
      creditLimit: freezed == creditLimit
          ? _value.creditLimit
          : creditLimit // ignore: cast_nullable_to_non_nullable
              as double?,
      billingDay: freezed == billingDay
          ? _value.billingDay
          : billingDay // ignore: cast_nullable_to_non_nullable
              as int?,
      paymentDueDay: freezed == paymentDueDay
          ? _value.paymentDueDay
          : paymentDueDay // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AccountModelImpl implements _AccountModel {
  const _$AccountModelImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.name,
      @HiveField(2) required this.nameBn,
      @HiveField(3) required this.type,
      @HiveField(4) required this.balance,
      @HiveField(5) this.icon,
      @HiveField(6) this.colorHex,
      @HiveField(7) this.isDefault = false,
      @HiveField(8) this.createdAt,
      @HiveField(9) this.updatedAt,
      @HiveField(10) this.nickname,
      @HiveField(11) this.userId,
      @HiveField(12) this.accountNumber,
      @HiveField(13) this.cardType,
      @HiveField(14) this.cardIssuer,
      @HiveField(15) this.cardholderName,
      @HiveField(16) this.creditLimit,
      @HiveField(17) this.billingDay,
      @HiveField(18) this.paymentDueDay});

  factory _$AccountModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AccountModelImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String name;
  @override
  @HiveField(2)
  final String nameBn;
  @override
  @HiveField(3)
  final AccountType type;
  @override
  @HiveField(4)
  final double balance;
  @override
  @HiveField(5)
  final String? icon;
  @override
  @HiveField(6)
  final String? colorHex;
  @override
  @JsonKey()
  @HiveField(7)
  final bool isDefault;
  @override
  @HiveField(8)
  final DateTime? createdAt;
  @override
  @HiveField(9)
  final DateTime? updatedAt;
  @override
  @HiveField(10)
  final String? nickname;
// User-editable custom name (e.g. "Salary Account")
  @override
  @HiveField(11)
  final String? userId;
  @override
  @HiveField(12)
  final String? accountNumber;
  @override
  @HiveField(13)
  final String? cardType;
  @override
  @HiveField(14)
  final String? cardIssuer;
  @override
  @HiveField(15)
  final String? cardholderName;
  @override
  @HiveField(16)
  final double? creditLimit;
  @override
  @HiveField(17)
  final int? billingDay;
  @override
  @HiveField(18)
  final int? paymentDueDay;

  @override
  String toString() {
    return 'AccountModel(id: $id, name: $name, nameBn: $nameBn, type: $type, balance: $balance, icon: $icon, colorHex: $colorHex, isDefault: $isDefault, createdAt: $createdAt, updatedAt: $updatedAt, nickname: $nickname, userId: $userId, accountNumber: $accountNumber, cardType: $cardType, cardIssuer: $cardIssuer, cardholderName: $cardholderName, creditLimit: $creditLimit, billingDay: $billingDay, paymentDueDay: $paymentDueDay)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.nameBn, nameBn) || other.nameBn == nameBn) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.colorHex, colorHex) ||
                other.colorHex == colorHex) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.accountNumber, accountNumber) ||
                other.accountNumber == accountNumber) &&
            (identical(other.cardType, cardType) ||
                other.cardType == cardType) &&
            (identical(other.cardIssuer, cardIssuer) ||
                other.cardIssuer == cardIssuer) &&
            (identical(other.cardholderName, cardholderName) ||
                other.cardholderName == cardholderName) &&
            (identical(other.creditLimit, creditLimit) ||
                other.creditLimit == creditLimit) &&
            (identical(other.billingDay, billingDay) ||
                other.billingDay == billingDay) &&
            (identical(other.paymentDueDay, paymentDueDay) ||
                other.paymentDueDay == paymentDueDay));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      nameBn,
      type,
      balance,
      icon,
      colorHex,
      isDefault,
      createdAt,
      updatedAt,
      nickname,
      userId,
      accountNumber,
      cardType,
      cardIssuer,
      cardholderName,
      creditLimit,
      billingDay,
      paymentDueDay);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountModelImplCopyWith<_$AccountModelImpl> get copyWith =>
      __$$AccountModelImplCopyWithImpl<_$AccountModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AccountModelImplToJson(
      this,
    );
  }
}

abstract class _AccountModel implements AccountModel {
  const factory _AccountModel(
      {@HiveField(0) required final String id,
      @HiveField(1) required final String name,
      @HiveField(2) required final String nameBn,
      @HiveField(3) required final AccountType type,
      @HiveField(4) required final double balance,
      @HiveField(5) final String? icon,
      @HiveField(6) final String? colorHex,
      @HiveField(7) final bool isDefault,
      @HiveField(8) final DateTime? createdAt,
      @HiveField(9) final DateTime? updatedAt,
      @HiveField(10) final String? nickname,
      @HiveField(11) final String? userId,
      @HiveField(12) final String? accountNumber,
      @HiveField(13) final String? cardType,
      @HiveField(14) final String? cardIssuer,
      @HiveField(15) final String? cardholderName,
      @HiveField(16) final double? creditLimit,
      @HiveField(17) final int? billingDay,
      @HiveField(18) final int? paymentDueDay}) = _$AccountModelImpl;

  factory _AccountModel.fromJson(Map<String, dynamic> json) =
      _$AccountModelImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get name;
  @override
  @HiveField(2)
  String get nameBn;
  @override
  @HiveField(3)
  AccountType get type;
  @override
  @HiveField(4)
  double get balance;
  @override
  @HiveField(5)
  String? get icon;
  @override
  @HiveField(6)
  String? get colorHex;
  @override
  @HiveField(7)
  bool get isDefault;
  @override
  @HiveField(8)
  DateTime? get createdAt;
  @override
  @HiveField(9)
  DateTime? get updatedAt;
  @override
  @HiveField(10)
  String? get nickname;
  @override // User-editable custom name (e.g. "Salary Account")
  @HiveField(11)
  String? get userId;
  @override
  @HiveField(12)
  String? get accountNumber;
  @override
  @HiveField(13)
  String? get cardType;
  @override
  @HiveField(14)
  String? get cardIssuer;
  @override
  @HiveField(15)
  String? get cardholderName;
  @override
  @HiveField(16)
  double? get creditLimit;
  @override
  @HiveField(17)
  int? get billingDay;
  @override
  @HiveField(18)
  int? get paymentDueDay;
  @override
  @JsonKey(ignore: true)
  _$$AccountModelImplCopyWith<_$AccountModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
