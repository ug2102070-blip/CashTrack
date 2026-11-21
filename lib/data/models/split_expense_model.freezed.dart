// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'split_expense_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SplitGroup _$SplitGroupFromJson(Map<String, dynamic> json) {
  return _SplitGroup.fromJson(json);
}

/// @nodoc
mixin _$SplitGroup {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get name => throw _privateConstructorUsedError;
  @HiveField(2)
  List<String> get members => throw _privateConstructorUsedError;
  @HiveField(3)
  DateTime get createdAt => throw _privateConstructorUsedError;
  @HiveField(4)
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SplitGroupCopyWith<SplitGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SplitGroupCopyWith<$Res> {
  factory $SplitGroupCopyWith(
          SplitGroup value, $Res Function(SplitGroup) then) =
      _$SplitGroupCopyWithImpl<$Res, SplitGroup>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String name,
      @HiveField(2) List<String> members,
      @HiveField(3) DateTime createdAt,
      @HiveField(4) DateTime? updatedAt});
}

/// @nodoc
class _$SplitGroupCopyWithImpl<$Res, $Val extends SplitGroup>
    implements $SplitGroupCopyWith<$Res> {
  _$SplitGroupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? members = null,
    Object? createdAt = null,
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
      members: null == members
          ? _value.members
          : members // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SplitGroupImplCopyWith<$Res>
    implements $SplitGroupCopyWith<$Res> {
  factory _$$SplitGroupImplCopyWith(
          _$SplitGroupImpl value, $Res Function(_$SplitGroupImpl) then) =
      __$$SplitGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String name,
      @HiveField(2) List<String> members,
      @HiveField(3) DateTime createdAt,
      @HiveField(4) DateTime? updatedAt});
}

/// @nodoc
class __$$SplitGroupImplCopyWithImpl<$Res>
    extends _$SplitGroupCopyWithImpl<$Res, _$SplitGroupImpl>
    implements _$$SplitGroupImplCopyWith<$Res> {
  __$$SplitGroupImplCopyWithImpl(
      _$SplitGroupImpl _value, $Res Function(_$SplitGroupImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? members = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_$SplitGroupImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      members: null == members
          ? _value._members
          : members // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SplitGroupImpl implements _SplitGroup {
  const _$SplitGroupImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.name,
      @HiveField(2) required final List<String> members,
      @HiveField(3) required this.createdAt,
      @HiveField(4) this.updatedAt})
      : _members = members;

  factory _$SplitGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$SplitGroupImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String name;
  final List<String> _members;
  @override
  @HiveField(2)
  List<String> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  @override
  @HiveField(3)
  final DateTime createdAt;
  @override
  @HiveField(4)
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'SplitGroup(id: $id, name: $name, members: $members, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SplitGroupImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._members, _members) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name,
      const DeepCollectionEquality().hash(_members), createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SplitGroupImplCopyWith<_$SplitGroupImpl> get copyWith =>
      __$$SplitGroupImplCopyWithImpl<_$SplitGroupImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SplitGroupImplToJson(
      this,
    );
  }
}

abstract class _SplitGroup implements SplitGroup {
  const factory _SplitGroup(
      {@HiveField(0) required final String id,
      @HiveField(1) required final String name,
      @HiveField(2) required final List<String> members,
      @HiveField(3) required final DateTime createdAt,
      @HiveField(4) final DateTime? updatedAt}) = _$SplitGroupImpl;

  factory _SplitGroup.fromJson(Map<String, dynamic> json) =
      _$SplitGroupImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get name;
  @override
  @HiveField(2)
  List<String> get members;
  @override
  @HiveField(3)
  DateTime get createdAt;
  @override
  @HiveField(4)
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$SplitGroupImplCopyWith<_$SplitGroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SplitExpense _$SplitExpenseFromJson(Map<String, dynamic> json) {
  return _SplitExpense.fromJson(json);
}

/// @nodoc
mixin _$SplitExpense {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get groupId => throw _privateConstructorUsedError;
  @HiveField(2)
  String get description => throw _privateConstructorUsedError;
  @HiveField(3)
  int get amount => throw _privateConstructorUsedError;
  @HiveField(4)
  String get paidBy => throw _privateConstructorUsedError;
  @HiveField(5)
  List<String> get splitAmong => throw _privateConstructorUsedError;
  @HiveField(6)
  DateTime get date => throw _privateConstructorUsedError;
  @HiveField(7)
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @HiveField(8)
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SplitExpenseCopyWith<SplitExpense> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SplitExpenseCopyWith<$Res> {
  factory $SplitExpenseCopyWith(
          SplitExpense value, $Res Function(SplitExpense) then) =
      _$SplitExpenseCopyWithImpl<$Res, SplitExpense>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String groupId,
      @HiveField(2) String description,
      @HiveField(3) int amount,
      @HiveField(4) String paidBy,
      @HiveField(5) List<String> splitAmong,
      @HiveField(6) DateTime date,
      @HiveField(7) DateTime? createdAt,
      @HiveField(8) DateTime? updatedAt});
}

/// @nodoc
class _$SplitExpenseCopyWithImpl<$Res, $Val extends SplitExpense>
    implements $SplitExpenseCopyWith<$Res> {
  _$SplitExpenseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? description = null,
    Object? amount = null,
    Object? paidBy = null,
    Object? splitAmong = null,
    Object? date = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      paidBy: null == paidBy
          ? _value.paidBy
          : paidBy // ignore: cast_nullable_to_non_nullable
              as String,
      splitAmong: null == splitAmong
          ? _value.splitAmong
          : splitAmong // ignore: cast_nullable_to_non_nullable
              as List<String>,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
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
abstract class _$$SplitExpenseImplCopyWith<$Res>
    implements $SplitExpenseCopyWith<$Res> {
  factory _$$SplitExpenseImplCopyWith(
          _$SplitExpenseImpl value, $Res Function(_$SplitExpenseImpl) then) =
      __$$SplitExpenseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String groupId,
      @HiveField(2) String description,
      @HiveField(3) int amount,
      @HiveField(4) String paidBy,
      @HiveField(5) List<String> splitAmong,
      @HiveField(6) DateTime date,
      @HiveField(7) DateTime? createdAt,
      @HiveField(8) DateTime? updatedAt});
}

/// @nodoc
class __$$SplitExpenseImplCopyWithImpl<$Res>
    extends _$SplitExpenseCopyWithImpl<$Res, _$SplitExpenseImpl>
    implements _$$SplitExpenseImplCopyWith<$Res> {
  __$$SplitExpenseImplCopyWithImpl(
      _$SplitExpenseImpl _value, $Res Function(_$SplitExpenseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? description = null,
    Object? amount = null,
    Object? paidBy = null,
    Object? splitAmong = null,
    Object? date = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$SplitExpenseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      paidBy: null == paidBy
          ? _value.paidBy
          : paidBy // ignore: cast_nullable_to_non_nullable
              as String,
      splitAmong: null == splitAmong
          ? _value._splitAmong
          : splitAmong // ignore: cast_nullable_to_non_nullable
              as List<String>,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
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
class _$SplitExpenseImpl implements _SplitExpense {
  const _$SplitExpenseImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.groupId,
      @HiveField(2) required this.description,
      @HiveField(3) required this.amount,
      @HiveField(4) required this.paidBy,
      @HiveField(5) required final List<String> splitAmong,
      @HiveField(6) required this.date,
      @HiveField(7) this.createdAt,
      @HiveField(8) this.updatedAt})
      : _splitAmong = splitAmong;

  factory _$SplitExpenseImpl.fromJson(Map<String, dynamic> json) =>
      _$$SplitExpenseImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String groupId;
  @override
  @HiveField(2)
  final String description;
  @override
  @HiveField(3)
  final int amount;
  @override
  @HiveField(4)
  final String paidBy;
  final List<String> _splitAmong;
  @override
  @HiveField(5)
  List<String> get splitAmong {
    if (_splitAmong is EqualUnmodifiableListView) return _splitAmong;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_splitAmong);
  }

  @override
  @HiveField(6)
  final DateTime date;
  @override
  @HiveField(7)
  final DateTime? createdAt;
  @override
  @HiveField(8)
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'SplitExpense(id: $id, groupId: $groupId, description: $description, amount: $amount, paidBy: $paidBy, splitAmong: $splitAmong, date: $date, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SplitExpenseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.paidBy, paidBy) || other.paidBy == paidBy) &&
            const DeepCollectionEquality()
                .equals(other._splitAmong, _splitAmong) &&
            (identical(other.date, date) || other.date == date) &&
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
      groupId,
      description,
      amount,
      paidBy,
      const DeepCollectionEquality().hash(_splitAmong),
      date,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SplitExpenseImplCopyWith<_$SplitExpenseImpl> get copyWith =>
      __$$SplitExpenseImplCopyWithImpl<_$SplitExpenseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SplitExpenseImplToJson(
      this,
    );
  }
}

abstract class _SplitExpense implements SplitExpense {
  const factory _SplitExpense(
      {@HiveField(0) required final String id,
      @HiveField(1) required final String groupId,
      @HiveField(2) required final String description,
      @HiveField(3) required final int amount,
      @HiveField(4) required final String paidBy,
      @HiveField(5) required final List<String> splitAmong,
      @HiveField(6) required final DateTime date,
      @HiveField(7) final DateTime? createdAt,
      @HiveField(8) final DateTime? updatedAt}) = _$SplitExpenseImpl;

  factory _SplitExpense.fromJson(Map<String, dynamic> json) =
      _$SplitExpenseImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get groupId;
  @override
  @HiveField(2)
  String get description;
  @override
  @HiveField(3)
  int get amount;
  @override
  @HiveField(4)
  String get paidBy;
  @override
  @HiveField(5)
  List<String> get splitAmong;
  @override
  @HiveField(6)
  DateTime get date;
  @override
  @HiveField(7)
  DateTime? get createdAt;
  @override
  @HiveField(8)
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$SplitExpenseImplCopyWith<_$SplitExpenseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
