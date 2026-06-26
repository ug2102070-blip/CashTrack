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
  DateTime? get updatedAt =>
      throw _privateConstructorUsedError; // ── Smart Debt Agreement Fields ──────────────────────
  @HiveField(10)
  String? get phoneNumber => throw _privateConstructorUsedError;
  @HiveField(11)
  AgreementStatus get agreementStatus => throw _privateConstructorUsedError;
  @HiveField(12)
  double get penaltyRate => throw _privateConstructorUsedError;
  @HiveField(13)
  double get penaltyAmount => throw _privateConstructorUsedError;
  @HiveField(14)
  String? get agreementTerms => throw _privateConstructorUsedError;
  @HiveField(15)
  int get trustScore => throw _privateConstructorUsedError;
  @HiveField(16)
  int get remindersSent => throw _privateConstructorUsedError;
  @HiveField(17)
  DateTime? get lastReminderAt => throw _privateConstructorUsedError;
  @HiveField(18)
  bool get hasAgreement => throw _privateConstructorUsedError;
  @HiveField(19)
  String? get paymentMethod => throw _privateConstructorUsedError;

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
      @HiveField(9) DateTime? updatedAt,
      @HiveField(10) String? phoneNumber,
      @HiveField(11) AgreementStatus agreementStatus,
      @HiveField(12) double penaltyRate,
      @HiveField(13) double penaltyAmount,
      @HiveField(14) String? agreementTerms,
      @HiveField(15) int trustScore,
      @HiveField(16) int remindersSent,
      @HiveField(17) DateTime? lastReminderAt,
      @HiveField(18) bool hasAgreement,
      @HiveField(19) String? paymentMethod});
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
    Object? phoneNumber = freezed,
    Object? agreementStatus = null,
    Object? penaltyRate = null,
    Object? penaltyAmount = null,
    Object? agreementTerms = freezed,
    Object? trustScore = null,
    Object? remindersSent = null,
    Object? lastReminderAt = freezed,
    Object? hasAgreement = null,
    Object? paymentMethod = freezed,
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
      phoneNumber: freezed == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      agreementStatus: null == agreementStatus
          ? _value.agreementStatus
          : agreementStatus // ignore: cast_nullable_to_non_nullable
              as AgreementStatus,
      penaltyRate: null == penaltyRate
          ? _value.penaltyRate
          : penaltyRate // ignore: cast_nullable_to_non_nullable
              as double,
      penaltyAmount: null == penaltyAmount
          ? _value.penaltyAmount
          : penaltyAmount // ignore: cast_nullable_to_non_nullable
              as double,
      agreementTerms: freezed == agreementTerms
          ? _value.agreementTerms
          : agreementTerms // ignore: cast_nullable_to_non_nullable
              as String?,
      trustScore: null == trustScore
          ? _value.trustScore
          : trustScore // ignore: cast_nullable_to_non_nullable
              as int,
      remindersSent: null == remindersSent
          ? _value.remindersSent
          : remindersSent // ignore: cast_nullable_to_non_nullable
              as int,
      lastReminderAt: freezed == lastReminderAt
          ? _value.lastReminderAt
          : lastReminderAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      hasAgreement: null == hasAgreement
          ? _value.hasAgreement
          : hasAgreement // ignore: cast_nullable_to_non_nullable
              as bool,
      paymentMethod: freezed == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String?,
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
      @HiveField(9) DateTime? updatedAt,
      @HiveField(10) String? phoneNumber,
      @HiveField(11) AgreementStatus agreementStatus,
      @HiveField(12) double penaltyRate,
      @HiveField(13) double penaltyAmount,
      @HiveField(14) String? agreementTerms,
      @HiveField(15) int trustScore,
      @HiveField(16) int remindersSent,
      @HiveField(17) DateTime? lastReminderAt,
      @HiveField(18) bool hasAgreement,
      @HiveField(19) String? paymentMethod});
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
    Object? phoneNumber = freezed,
    Object? agreementStatus = null,
    Object? penaltyRate = null,
    Object? penaltyAmount = null,
    Object? agreementTerms = freezed,
    Object? trustScore = null,
    Object? remindersSent = null,
    Object? lastReminderAt = freezed,
    Object? hasAgreement = null,
    Object? paymentMethod = freezed,
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
      phoneNumber: freezed == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      agreementStatus: null == agreementStatus
          ? _value.agreementStatus
          : agreementStatus // ignore: cast_nullable_to_non_nullable
              as AgreementStatus,
      penaltyRate: null == penaltyRate
          ? _value.penaltyRate
          : penaltyRate // ignore: cast_nullable_to_non_nullable
              as double,
      penaltyAmount: null == penaltyAmount
          ? _value.penaltyAmount
          : penaltyAmount // ignore: cast_nullable_to_non_nullable
              as double,
      agreementTerms: freezed == agreementTerms
          ? _value.agreementTerms
          : agreementTerms // ignore: cast_nullable_to_non_nullable
              as String?,
      trustScore: null == trustScore
          ? _value.trustScore
          : trustScore // ignore: cast_nullable_to_non_nullable
              as int,
      remindersSent: null == remindersSent
          ? _value.remindersSent
          : remindersSent // ignore: cast_nullable_to_non_nullable
              as int,
      lastReminderAt: freezed == lastReminderAt
          ? _value.lastReminderAt
          : lastReminderAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      hasAgreement: null == hasAgreement
          ? _value.hasAgreement
          : hasAgreement // ignore: cast_nullable_to_non_nullable
              as bool,
      paymentMethod: freezed == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String?,
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
      @HiveField(9) this.updatedAt,
      @HiveField(10) this.phoneNumber,
      @HiveField(11) this.agreementStatus = AgreementStatus.pending,
      @HiveField(12) this.penaltyRate = 0,
      @HiveField(13) this.penaltyAmount = 0,
      @HiveField(14) this.agreementTerms,
      @HiveField(15) this.trustScore = 100,
      @HiveField(16) this.remindersSent = 0,
      @HiveField(17) this.lastReminderAt,
      @HiveField(18) this.hasAgreement = false,
      @HiveField(19) this.paymentMethod});

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
// ── Smart Debt Agreement Fields ──────────────────────
  @override
  @HiveField(10)
  final String? phoneNumber;
  @override
  @JsonKey()
  @HiveField(11)
  final AgreementStatus agreementStatus;
  @override
  @JsonKey()
  @HiveField(12)
  final double penaltyRate;
  @override
  @JsonKey()
  @HiveField(13)
  final double penaltyAmount;
  @override
  @HiveField(14)
  final String? agreementTerms;
  @override
  @JsonKey()
  @HiveField(15)
  final int trustScore;
  @override
  @JsonKey()
  @HiveField(16)
  final int remindersSent;
  @override
  @HiveField(17)
  final DateTime? lastReminderAt;
  @override
  @JsonKey()
  @HiveField(18)
  final bool hasAgreement;
  @override
  @HiveField(19)
  final String? paymentMethod;

  @override
  String toString() {
    return 'DebtModel(id: $id, type: $type, personName: $personName, amount: $amount, paidAmount: $paidAmount, dueDate: $dueDate, note: $note, isSettled: $isSettled, createdAt: $createdAt, updatedAt: $updatedAt, phoneNumber: $phoneNumber, agreementStatus: $agreementStatus, penaltyRate: $penaltyRate, penaltyAmount: $penaltyAmount, agreementTerms: $agreementTerms, trustScore: $trustScore, remindersSent: $remindersSent, lastReminderAt: $lastReminderAt, hasAgreement: $hasAgreement, paymentMethod: $paymentMethod)';
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
                other.updatedAt == updatedAt) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.agreementStatus, agreementStatus) ||
                other.agreementStatus == agreementStatus) &&
            (identical(other.penaltyRate, penaltyRate) ||
                other.penaltyRate == penaltyRate) &&
            (identical(other.penaltyAmount, penaltyAmount) ||
                other.penaltyAmount == penaltyAmount) &&
            (identical(other.agreementTerms, agreementTerms) ||
                other.agreementTerms == agreementTerms) &&
            (identical(other.trustScore, trustScore) ||
                other.trustScore == trustScore) &&
            (identical(other.remindersSent, remindersSent) ||
                other.remindersSent == remindersSent) &&
            (identical(other.lastReminderAt, lastReminderAt) ||
                other.lastReminderAt == lastReminderAt) &&
            (identical(other.hasAgreement, hasAgreement) ||
                other.hasAgreement == hasAgreement) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        type,
        personName,
        amount,
        paidAmount,
        dueDate,
        note,
        isSettled,
        createdAt,
        updatedAt,
        phoneNumber,
        agreementStatus,
        penaltyRate,
        penaltyAmount,
        agreementTerms,
        trustScore,
        remindersSent,
        lastReminderAt,
        hasAgreement,
        paymentMethod
      ]);

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
      @HiveField(9) final DateTime? updatedAt,
      @HiveField(10) final String? phoneNumber,
      @HiveField(11) final AgreementStatus agreementStatus,
      @HiveField(12) final double penaltyRate,
      @HiveField(13) final double penaltyAmount,
      @HiveField(14) final String? agreementTerms,
      @HiveField(15) final int trustScore,
      @HiveField(16) final int remindersSent,
      @HiveField(17) final DateTime? lastReminderAt,
      @HiveField(18) final bool hasAgreement,
      @HiveField(19) final String? paymentMethod}) = _$DebtModelImpl;

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
  @override // ── Smart Debt Agreement Fields ──────────────────────
  @HiveField(10)
  String? get phoneNumber;
  @override
  @HiveField(11)
  AgreementStatus get agreementStatus;
  @override
  @HiveField(12)
  double get penaltyRate;
  @override
  @HiveField(13)
  double get penaltyAmount;
  @override
  @HiveField(14)
  String? get agreementTerms;
  @override
  @HiveField(15)
  int get trustScore;
  @override
  @HiveField(16)
  int get remindersSent;
  @override
  @HiveField(17)
  DateTime? get lastReminderAt;
  @override
  @HiveField(18)
  bool get hasAgreement;
  @override
  @HiveField(19)
  String? get paymentMethod;
  @override
  @JsonKey(ignore: true)
  _$$DebtModelImplCopyWith<_$DebtModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
