// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) {
  return _TransactionModel.fromJson(json);
}

/// @nodoc
mixin _$TransactionModel {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  TransactionType get type => throw _privateConstructorUsedError;
  @HiveField(2)
  double get amount => throw _privateConstructorUsedError;
  @HiveField(3)
  String get categoryId => throw _privateConstructorUsedError;
  @HiveField(4)
  String get accountId => throw _privateConstructorUsedError;
  @HiveField(5)
  DateTime get date => throw _privateConstructorUsedError;
  @HiveField(6)
  String? get note => throw _privateConstructorUsedError;
  @HiveField(7)
  String? get receiptUrl => throw _privateConstructorUsedError;
  @HiveField(8)
  bool get isRecurring => throw _privateConstructorUsedError;
  @HiveField(9)
  RecurringType? get recurringType => throw _privateConstructorUsedError;
  @HiveField(10)
  bool get isSynced => throw _privateConstructorUsedError;
  @HiveField(11)
  bool get isDeleted => throw _privateConstructorUsedError;
  @HiveField(12)
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @HiveField(13)
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @HiveField(14)
  String? get smsId => throw _privateConstructorUsedError;
  @HiveField(15)
  String? get toAccountId =>
      throw _privateConstructorUsedError; // For transfers
  @HiveField(16)
  List<String> get tags =>
      throw _privateConstructorUsedError; // For SMS auto-categorization
  @HiveField(17)
  double get confidenceScore => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TransactionModelCopyWith<TransactionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionModelCopyWith<$Res> {
  factory $TransactionModelCopyWith(
          TransactionModel value, $Res Function(TransactionModel) then) =
      _$TransactionModelCopyWithImpl<$Res, TransactionModel>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) TransactionType type,
      @HiveField(2) double amount,
      @HiveField(3) String categoryId,
      @HiveField(4) String accountId,
      @HiveField(5) DateTime date,
      @HiveField(6) String? note,
      @HiveField(7) String? receiptUrl,
      @HiveField(8) bool isRecurring,
      @HiveField(9) RecurringType? recurringType,
      @HiveField(10) bool isSynced,
      @HiveField(11) bool isDeleted,
      @HiveField(12) DateTime? createdAt,
      @HiveField(13) DateTime? updatedAt,
      @HiveField(14) String? smsId,
      @HiveField(15) String? toAccountId,
      @HiveField(16) List<String> tags,
      @HiveField(17) double confidenceScore});
}

/// @nodoc
class _$TransactionModelCopyWithImpl<$Res, $Val extends TransactionModel>
    implements $TransactionModelCopyWith<$Res> {
  _$TransactionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? amount = null,
    Object? categoryId = null,
    Object? accountId = null,
    Object? date = null,
    Object? note = freezed,
    Object? receiptUrl = freezed,
    Object? isRecurring = null,
    Object? recurringType = freezed,
    Object? isSynced = null,
    Object? isDeleted = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? smsId = freezed,
    Object? toAccountId = freezed,
    Object? tags = null,
    Object? confidenceScore = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TransactionType,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      accountId: null == accountId
          ? _value.accountId
          : accountId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      receiptUrl: freezed == receiptUrl
          ? _value.receiptUrl
          : receiptUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isRecurring: null == isRecurring
          ? _value.isRecurring
          : isRecurring // ignore: cast_nullable_to_non_nullable
              as bool,
      recurringType: freezed == recurringType
          ? _value.recurringType
          : recurringType // ignore: cast_nullable_to_non_nullable
              as RecurringType?,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      smsId: freezed == smsId
          ? _value.smsId
          : smsId // ignore: cast_nullable_to_non_nullable
              as String?,
      toAccountId: freezed == toAccountId
          ? _value.toAccountId
          : toAccountId // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      confidenceScore: null == confidenceScore
          ? _value.confidenceScore
          : confidenceScore // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TransactionModelImplCopyWith<$Res>
    implements $TransactionModelCopyWith<$Res> {
  factory _$$TransactionModelImplCopyWith(_$TransactionModelImpl value,
          $Res Function(_$TransactionModelImpl) then) =
      __$$TransactionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) TransactionType type,
      @HiveField(2) double amount,
      @HiveField(3) String categoryId,
      @HiveField(4) String accountId,
      @HiveField(5) DateTime date,
      @HiveField(6) String? note,
      @HiveField(7) String? receiptUrl,
      @HiveField(8) bool isRecurring,
      @HiveField(9) RecurringType? recurringType,
      @HiveField(10) bool isSynced,
      @HiveField(11) bool isDeleted,
      @HiveField(12) DateTime? createdAt,
      @HiveField(13) DateTime? updatedAt,
      @HiveField(14) String? smsId,
      @HiveField(15) String? toAccountId,
      @HiveField(16) List<String> tags,
      @HiveField(17) double confidenceScore});
}

/// @nodoc
class __$$TransactionModelImplCopyWithImpl<$Res>
    extends _$TransactionModelCopyWithImpl<$Res, _$TransactionModelImpl>
    implements _$$TransactionModelImplCopyWith<$Res> {
  __$$TransactionModelImplCopyWithImpl(_$TransactionModelImpl _value,
      $Res Function(_$TransactionModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? amount = null,
    Object? categoryId = null,
    Object? accountId = null,
    Object? date = null,
    Object? note = freezed,
    Object? receiptUrl = freezed,
    Object? isRecurring = null,
    Object? recurringType = freezed,
    Object? isSynced = null,
    Object? isDeleted = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? smsId = freezed,
    Object? toAccountId = freezed,
    Object? tags = null,
    Object? confidenceScore = null,
  }) {
    return _then(_$TransactionModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TransactionType,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      accountId: null == accountId
          ? _value.accountId
          : accountId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      receiptUrl: freezed == receiptUrl
          ? _value.receiptUrl
          : receiptUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isRecurring: null == isRecurring
          ? _value.isRecurring
          : isRecurring // ignore: cast_nullable_to_non_nullable
              as bool,
      recurringType: freezed == recurringType
          ? _value.recurringType
          : recurringType // ignore: cast_nullable_to_non_nullable
              as RecurringType?,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      smsId: freezed == smsId
          ? _value.smsId
          : smsId // ignore: cast_nullable_to_non_nullable
              as String?,
      toAccountId: freezed == toAccountId
          ? _value.toAccountId
          : toAccountId // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      confidenceScore: null == confidenceScore
          ? _value.confidenceScore
          : confidenceScore // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TransactionModelImpl implements _TransactionModel {
  const _$TransactionModelImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.type,
      @HiveField(2) required this.amount,
      @HiveField(3) required this.categoryId,
      @HiveField(4) required this.accountId,
      @HiveField(5) required this.date,
      @HiveField(6) this.note,
      @HiveField(7) this.receiptUrl,
      @HiveField(8) this.isRecurring = false,
      @HiveField(9) this.recurringType,
      @HiveField(10) this.isSynced = false,
      @HiveField(11) this.isDeleted = false,
      @HiveField(12) this.createdAt,
      @HiveField(13) this.updatedAt,
      @HiveField(14) this.smsId,
      @HiveField(15) this.toAccountId,
      @HiveField(16) final List<String> tags = const [],
      @HiveField(17) this.confidenceScore = 0.0})
      : _tags = tags;

  factory _$TransactionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransactionModelImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final TransactionType type;
  @override
  @HiveField(2)
  final double amount;
  @override
  @HiveField(3)
  final String categoryId;
  @override
  @HiveField(4)
  final String accountId;
  @override
  @HiveField(5)
  final DateTime date;
  @override
  @HiveField(6)
  final String? note;
  @override
  @HiveField(7)
  final String? receiptUrl;
  @override
  @JsonKey()
  @HiveField(8)
  final bool isRecurring;
  @override
  @HiveField(9)
  final RecurringType? recurringType;
  @override
  @JsonKey()
  @HiveField(10)
  final bool isSynced;
  @override
  @JsonKey()
  @HiveField(11)
  final bool isDeleted;
  @override
  @HiveField(12)
  final DateTime? createdAt;
  @override
  @HiveField(13)
  final DateTime? updatedAt;
  @override
  @HiveField(14)
  final String? smsId;
  @override
  @HiveField(15)
  final String? toAccountId;
// For transfers
  final List<String> _tags;
// For transfers
  @override
  @JsonKey()
  @HiveField(16)
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

// For SMS auto-categorization
  @override
  @JsonKey()
  @HiveField(17)
  final double confidenceScore;

  @override
  String toString() {
    return 'TransactionModel(id: $id, type: $type, amount: $amount, categoryId: $categoryId, accountId: $accountId, date: $date, note: $note, receiptUrl: $receiptUrl, isRecurring: $isRecurring, recurringType: $recurringType, isSynced: $isSynced, isDeleted: $isDeleted, createdAt: $createdAt, updatedAt: $updatedAt, smsId: $smsId, toAccountId: $toAccountId, tags: $tags, confidenceScore: $confidenceScore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.receiptUrl, receiptUrl) ||
                other.receiptUrl == receiptUrl) &&
            (identical(other.isRecurring, isRecurring) ||
                other.isRecurring == isRecurring) &&
            (identical(other.recurringType, recurringType) ||
                other.recurringType == recurringType) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.smsId, smsId) || other.smsId == smsId) &&
            (identical(other.toAccountId, toAccountId) ||
                other.toAccountId == toAccountId) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.confidenceScore, confidenceScore) ||
                other.confidenceScore == confidenceScore));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      type,
      amount,
      categoryId,
      accountId,
      date,
      note,
      receiptUrl,
      isRecurring,
      recurringType,
      isSynced,
      isDeleted,
      createdAt,
      updatedAt,
      smsId,
      toAccountId,
      const DeepCollectionEquality().hash(_tags),
      confidenceScore);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionModelImplCopyWith<_$TransactionModelImpl> get copyWith =>
      __$$TransactionModelImplCopyWithImpl<_$TransactionModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TransactionModelImplToJson(
      this,
    );
  }
}

abstract class _TransactionModel implements TransactionModel {
  const factory _TransactionModel(
      {@HiveField(0) required final String id,
      @HiveField(1) required final TransactionType type,
      @HiveField(2) required final double amount,
      @HiveField(3) required final String categoryId,
      @HiveField(4) required final String accountId,
      @HiveField(5) required final DateTime date,
      @HiveField(6) final String? note,
      @HiveField(7) final String? receiptUrl,
      @HiveField(8) final bool isRecurring,
      @HiveField(9) final RecurringType? recurringType,
      @HiveField(10) final bool isSynced,
      @HiveField(11) final bool isDeleted,
      @HiveField(12) final DateTime? createdAt,
      @HiveField(13) final DateTime? updatedAt,
      @HiveField(14) final String? smsId,
      @HiveField(15) final String? toAccountId,
      @HiveField(16) final List<String> tags,
      @HiveField(17) final double confidenceScore}) = _$TransactionModelImpl;

  factory _TransactionModel.fromJson(Map<String, dynamic> json) =
      _$TransactionModelImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  TransactionType get type;
  @override
  @HiveField(2)
  double get amount;
  @override
  @HiveField(3)
  String get categoryId;
  @override
  @HiveField(4)
  String get accountId;
  @override
  @HiveField(5)
  DateTime get date;
  @override
  @HiveField(6)
  String? get note;
  @override
  @HiveField(7)
  String? get receiptUrl;
  @override
  @HiveField(8)
  bool get isRecurring;
  @override
  @HiveField(9)
  RecurringType? get recurringType;
  @override
  @HiveField(10)
  bool get isSynced;
  @override
  @HiveField(11)
  bool get isDeleted;
  @override
  @HiveField(12)
  DateTime? get createdAt;
  @override
  @HiveField(13)
  DateTime? get updatedAt;
  @override
  @HiveField(14)
  String? get smsId;
  @override
  @HiveField(15)
  String? get toAccountId;
  @override // For transfers
  @HiveField(16)
  List<String> get tags;
  @override // For SMS auto-categorization
  @HiveField(17)
  double get confidenceScore;
  @override
  @JsonKey(ignore: true)
  _$$TransactionModelImplCopyWith<_$TransactionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
