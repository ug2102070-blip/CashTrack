// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return _UserModel.fromJson(json);
}

/// @nodoc
mixin _$UserModel {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get email => throw _privateConstructorUsedError;
  @HiveField(2)
  String? get displayName => throw _privateConstructorUsedError;
  @HiveField(3)
  String? get photoURL => throw _privateConstructorUsedError;
  @HiveField(4)
  UserSettings? get settings => throw _privateConstructorUsedError;
  @HiveField(5)
  UserStats? get stats => throw _privateConstructorUsedError;
  @HiveField(6)
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @HiveField(7)
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String email,
      @HiveField(2) String? displayName,
      @HiveField(3) String? photoURL,
      @HiveField(4) UserSettings? settings,
      @HiveField(5) UserStats? stats,
      @HiveField(6) DateTime? createdAt,
      @HiveField(7) DateTime? updatedAt});

  $UserSettingsCopyWith<$Res>? get settings;
  $UserStatsCopyWith<$Res>? get stats;
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? displayName = freezed,
    Object? photoURL = freezed,
    Object? settings = freezed,
    Object? stats = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      photoURL: freezed == photoURL
          ? _value.photoURL
          : photoURL // ignore: cast_nullable_to_non_nullable
              as String?,
      settings: freezed == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as UserSettings?,
      stats: freezed == stats
          ? _value.stats
          : stats // ignore: cast_nullable_to_non_nullable
              as UserStats?,
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

  @override
  @pragma('vm:prefer-inline')
  $UserSettingsCopyWith<$Res>? get settings {
    if (_value.settings == null) {
      return null;
    }

    return $UserSettingsCopyWith<$Res>(_value.settings!, (value) {
      return _then(_value.copyWith(settings: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $UserStatsCopyWith<$Res>? get stats {
    if (_value.stats == null) {
      return null;
    }

    return $UserStatsCopyWith<$Res>(_value.stats!, (value) {
      return _then(_value.copyWith(stats: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
          _$UserModelImpl value, $Res Function(_$UserModelImpl) then) =
      __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String email,
      @HiveField(2) String? displayName,
      @HiveField(3) String? photoURL,
      @HiveField(4) UserSettings? settings,
      @HiveField(5) UserStats? stats,
      @HiveField(6) DateTime? createdAt,
      @HiveField(7) DateTime? updatedAt});

  @override
  $UserSettingsCopyWith<$Res>? get settings;
  @override
  $UserStatsCopyWith<$Res>? get stats;
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
      _$UserModelImpl _value, $Res Function(_$UserModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? displayName = freezed,
    Object? photoURL = freezed,
    Object? settings = freezed,
    Object? stats = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$UserModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      photoURL: freezed == photoURL
          ? _value.photoURL
          : photoURL // ignore: cast_nullable_to_non_nullable
              as String?,
      settings: freezed == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as UserSettings?,
      stats: freezed == stats
          ? _value.stats
          : stats // ignore: cast_nullable_to_non_nullable
              as UserStats?,
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
class _$UserModelImpl implements _UserModel {
  const _$UserModelImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.email,
      @HiveField(2) this.displayName,
      @HiveField(3) this.photoURL,
      @HiveField(4) this.settings,
      @HiveField(5) this.stats,
      @HiveField(6) this.createdAt,
      @HiveField(7) this.updatedAt});

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String email;
  @override
  @HiveField(2)
  final String? displayName;
  @override
  @HiveField(3)
  final String? photoURL;
  @override
  @HiveField(4)
  final UserSettings? settings;
  @override
  @HiveField(5)
  final UserStats? stats;
  @override
  @HiveField(6)
  final DateTime? createdAt;
  @override
  @HiveField(7)
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, photoURL: $photoURL, settings: $settings, stats: $stats, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.photoURL, photoURL) ||
                other.photoURL == photoURL) &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            (identical(other.stats, stats) || other.stats == stats) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, email, displayName, photoURL,
      settings, stats, createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserModelImplToJson(
      this,
    );
  }
}

abstract class _UserModel implements UserModel {
  const factory _UserModel(
      {@HiveField(0) required final String id,
      @HiveField(1) required final String email,
      @HiveField(2) final String? displayName,
      @HiveField(3) final String? photoURL,
      @HiveField(4) final UserSettings? settings,
      @HiveField(5) final UserStats? stats,
      @HiveField(6) final DateTime? createdAt,
      @HiveField(7) final DateTime? updatedAt}) = _$UserModelImpl;

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get email;
  @override
  @HiveField(2)
  String? get displayName;
  @override
  @HiveField(3)
  String? get photoURL;
  @override
  @HiveField(4)
  UserSettings? get settings;
  @override
  @HiveField(5)
  UserStats? get stats;
  @override
  @HiveField(6)
  DateTime? get createdAt;
  @override
  @HiveField(7)
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) {
  return _UserSettings.fromJson(json);
}

/// @nodoc
mixin _$UserSettings {
  @HiveField(0)
  String get currency => throw _privateConstructorUsedError;
  @HiveField(1)
  String get currencySymbol => throw _privateConstructorUsedError;
  @HiveField(2)
  String get language => throw _privateConstructorUsedError;
  @HiveField(3)
  bool get darkMode => throw _privateConstructorUsedError;
  @HiveField(4)
  String get accentColor => throw _privateConstructorUsedError;
  @HiveField(5)
  bool get rolloverBudget => throw _privateConstructorUsedError;
  @HiveField(6)
  bool get smsAutoImport => throw _privateConstructorUsedError;
  @HiveField(7)
  bool get biometricEnabled => throw _privateConstructorUsedError;
  @HiveField(8)
  bool get notificationsEnabled => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserSettingsCopyWith<UserSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSettingsCopyWith<$Res> {
  factory $UserSettingsCopyWith(
          UserSettings value, $Res Function(UserSettings) then) =
      _$UserSettingsCopyWithImpl<$Res, UserSettings>;
  @useResult
  $Res call(
      {@HiveField(0) String currency,
      @HiveField(1) String currencySymbol,
      @HiveField(2) String language,
      @HiveField(3) bool darkMode,
      @HiveField(4) String accentColor,
      @HiveField(5) bool rolloverBudget,
      @HiveField(6) bool smsAutoImport,
      @HiveField(7) bool biometricEnabled,
      @HiveField(8) bool notificationsEnabled});
}

/// @nodoc
class _$UserSettingsCopyWithImpl<$Res, $Val extends UserSettings>
    implements $UserSettingsCopyWith<$Res> {
  _$UserSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currency = null,
    Object? currencySymbol = null,
    Object? language = null,
    Object? darkMode = null,
    Object? accentColor = null,
    Object? rolloverBudget = null,
    Object? smsAutoImport = null,
    Object? biometricEnabled = null,
    Object? notificationsEnabled = null,
  }) {
    return _then(_value.copyWith(
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      currencySymbol: null == currencySymbol
          ? _value.currencySymbol
          : currencySymbol // ignore: cast_nullable_to_non_nullable
              as String,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      darkMode: null == darkMode
          ? _value.darkMode
          : darkMode // ignore: cast_nullable_to_non_nullable
              as bool,
      accentColor: null == accentColor
          ? _value.accentColor
          : accentColor // ignore: cast_nullable_to_non_nullable
              as String,
      rolloverBudget: null == rolloverBudget
          ? _value.rolloverBudget
          : rolloverBudget // ignore: cast_nullable_to_non_nullable
              as bool,
      smsAutoImport: null == smsAutoImport
          ? _value.smsAutoImport
          : smsAutoImport // ignore: cast_nullable_to_non_nullable
              as bool,
      biometricEnabled: null == biometricEnabled
          ? _value.biometricEnabled
          : biometricEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      notificationsEnabled: null == notificationsEnabled
          ? _value.notificationsEnabled
          : notificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserSettingsImplCopyWith<$Res>
    implements $UserSettingsCopyWith<$Res> {
  factory _$$UserSettingsImplCopyWith(
          _$UserSettingsImpl value, $Res Function(_$UserSettingsImpl) then) =
      __$$UserSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String currency,
      @HiveField(1) String currencySymbol,
      @HiveField(2) String language,
      @HiveField(3) bool darkMode,
      @HiveField(4) String accentColor,
      @HiveField(5) bool rolloverBudget,
      @HiveField(6) bool smsAutoImport,
      @HiveField(7) bool biometricEnabled,
      @HiveField(8) bool notificationsEnabled});
}

/// @nodoc
class __$$UserSettingsImplCopyWithImpl<$Res>
    extends _$UserSettingsCopyWithImpl<$Res, _$UserSettingsImpl>
    implements _$$UserSettingsImplCopyWith<$Res> {
  __$$UserSettingsImplCopyWithImpl(
      _$UserSettingsImpl _value, $Res Function(_$UserSettingsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currency = null,
    Object? currencySymbol = null,
    Object? language = null,
    Object? darkMode = null,
    Object? accentColor = null,
    Object? rolloverBudget = null,
    Object? smsAutoImport = null,
    Object? biometricEnabled = null,
    Object? notificationsEnabled = null,
  }) {
    return _then(_$UserSettingsImpl(
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      currencySymbol: null == currencySymbol
          ? _value.currencySymbol
          : currencySymbol // ignore: cast_nullable_to_non_nullable
              as String,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      darkMode: null == darkMode
          ? _value.darkMode
          : darkMode // ignore: cast_nullable_to_non_nullable
              as bool,
      accentColor: null == accentColor
          ? _value.accentColor
          : accentColor // ignore: cast_nullable_to_non_nullable
              as String,
      rolloverBudget: null == rolloverBudget
          ? _value.rolloverBudget
          : rolloverBudget // ignore: cast_nullable_to_non_nullable
              as bool,
      smsAutoImport: null == smsAutoImport
          ? _value.smsAutoImport
          : smsAutoImport // ignore: cast_nullable_to_non_nullable
              as bool,
      biometricEnabled: null == biometricEnabled
          ? _value.biometricEnabled
          : biometricEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      notificationsEnabled: null == notificationsEnabled
          ? _value.notificationsEnabled
          : notificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSettingsImpl implements _UserSettings {
  const _$UserSettingsImpl(
      {@HiveField(0) this.currency = 'BDT',
      @HiveField(1) this.currencySymbol = '৳',
      @HiveField(2) this.language = 'en',
      @HiveField(3) this.darkMode = false,
      @HiveField(4) this.accentColor = '#2D7A7B',
      @HiveField(5) this.rolloverBudget = false,
      @HiveField(6) this.smsAutoImport = true,
      @HiveField(7) this.biometricEnabled = false,
      @HiveField(8) this.notificationsEnabled = true});

  factory _$UserSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSettingsImplFromJson(json);

  @override
  @JsonKey()
  @HiveField(0)
  final String currency;
  @override
  @JsonKey()
  @HiveField(1)
  final String currencySymbol;
  @override
  @JsonKey()
  @HiveField(2)
  final String language;
  @override
  @JsonKey()
  @HiveField(3)
  final bool darkMode;
  @override
  @JsonKey()
  @HiveField(4)
  final String accentColor;
  @override
  @JsonKey()
  @HiveField(5)
  final bool rolloverBudget;
  @override
  @JsonKey()
  @HiveField(6)
  final bool smsAutoImport;
  @override
  @JsonKey()
  @HiveField(7)
  final bool biometricEnabled;
  @override
  @JsonKey()
  @HiveField(8)
  final bool notificationsEnabled;

  @override
  String toString() {
    return 'UserSettings(currency: $currency, currencySymbol: $currencySymbol, language: $language, darkMode: $darkMode, accentColor: $accentColor, rolloverBudget: $rolloverBudget, smsAutoImport: $smsAutoImport, biometricEnabled: $biometricEnabled, notificationsEnabled: $notificationsEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSettingsImpl &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.currencySymbol, currencySymbol) ||
                other.currencySymbol == currencySymbol) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.darkMode, darkMode) ||
                other.darkMode == darkMode) &&
            (identical(other.accentColor, accentColor) ||
                other.accentColor == accentColor) &&
            (identical(other.rolloverBudget, rolloverBudget) ||
                other.rolloverBudget == rolloverBudget) &&
            (identical(other.smsAutoImport, smsAutoImport) ||
                other.smsAutoImport == smsAutoImport) &&
            (identical(other.biometricEnabled, biometricEnabled) ||
                other.biometricEnabled == biometricEnabled) &&
            (identical(other.notificationsEnabled, notificationsEnabled) ||
                other.notificationsEnabled == notificationsEnabled));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      currency,
      currencySymbol,
      language,
      darkMode,
      accentColor,
      rolloverBudget,
      smsAutoImport,
      biometricEnabled,
      notificationsEnabled);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      __$$UserSettingsImplCopyWithImpl<_$UserSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSettingsImplToJson(
      this,
    );
  }
}

abstract class _UserSettings implements UserSettings {
  const factory _UserSettings(
      {@HiveField(0) final String currency,
      @HiveField(1) final String currencySymbol,
      @HiveField(2) final String language,
      @HiveField(3) final bool darkMode,
      @HiveField(4) final String accentColor,
      @HiveField(5) final bool rolloverBudget,
      @HiveField(6) final bool smsAutoImport,
      @HiveField(7) final bool biometricEnabled,
      @HiveField(8) final bool notificationsEnabled}) = _$UserSettingsImpl;

  factory _UserSettings.fromJson(Map<String, dynamic> json) =
      _$UserSettingsImpl.fromJson;

  @override
  @HiveField(0)
  String get currency;
  @override
  @HiveField(1)
  String get currencySymbol;
  @override
  @HiveField(2)
  String get language;
  @override
  @HiveField(3)
  bool get darkMode;
  @override
  @HiveField(4)
  String get accentColor;
  @override
  @HiveField(5)
  bool get rolloverBudget;
  @override
  @HiveField(6)
  bool get smsAutoImport;
  @override
  @HiveField(7)
  bool get biometricEnabled;
  @override
  @HiveField(8)
  bool get notificationsEnabled;
  @override
  @JsonKey(ignore: true)
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserStats _$UserStatsFromJson(Map<String, dynamic> json) {
  return _UserStats.fromJson(json);
}

/// @nodoc
mixin _$UserStats {
  @HiveField(0)
  double get totalBalance => throw _privateConstructorUsedError;
  @HiveField(1)
  double get totalIncome => throw _privateConstructorUsedError;
  @HiveField(2)
  double get totalExpense => throw _privateConstructorUsedError;
  @HiveField(3)
  int get transactionCount => throw _privateConstructorUsedError;
  @HiveField(4)
  DateTime? get lastSyncTime => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserStatsCopyWith<UserStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserStatsCopyWith<$Res> {
  factory $UserStatsCopyWith(UserStats value, $Res Function(UserStats) then) =
      _$UserStatsCopyWithImpl<$Res, UserStats>;
  @useResult
  $Res call(
      {@HiveField(0) double totalBalance,
      @HiveField(1) double totalIncome,
      @HiveField(2) double totalExpense,
      @HiveField(3) int transactionCount,
      @HiveField(4) DateTime? lastSyncTime});
}

/// @nodoc
class _$UserStatsCopyWithImpl<$Res, $Val extends UserStats>
    implements $UserStatsCopyWith<$Res> {
  _$UserStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalBalance = null,
    Object? totalIncome = null,
    Object? totalExpense = null,
    Object? transactionCount = null,
    Object? lastSyncTime = freezed,
  }) {
    return _then(_value.copyWith(
      totalBalance: null == totalBalance
          ? _value.totalBalance
          : totalBalance // ignore: cast_nullable_to_non_nullable
              as double,
      totalIncome: null == totalIncome
          ? _value.totalIncome
          : totalIncome // ignore: cast_nullable_to_non_nullable
              as double,
      totalExpense: null == totalExpense
          ? _value.totalExpense
          : totalExpense // ignore: cast_nullable_to_non_nullable
              as double,
      transactionCount: null == transactionCount
          ? _value.transactionCount
          : transactionCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastSyncTime: freezed == lastSyncTime
          ? _value.lastSyncTime
          : lastSyncTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserStatsImplCopyWith<$Res>
    implements $UserStatsCopyWith<$Res> {
  factory _$$UserStatsImplCopyWith(
          _$UserStatsImpl value, $Res Function(_$UserStatsImpl) then) =
      __$$UserStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) double totalBalance,
      @HiveField(1) double totalIncome,
      @HiveField(2) double totalExpense,
      @HiveField(3) int transactionCount,
      @HiveField(4) DateTime? lastSyncTime});
}

/// @nodoc
class __$$UserStatsImplCopyWithImpl<$Res>
    extends _$UserStatsCopyWithImpl<$Res, _$UserStatsImpl>
    implements _$$UserStatsImplCopyWith<$Res> {
  __$$UserStatsImplCopyWithImpl(
      _$UserStatsImpl _value, $Res Function(_$UserStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalBalance = null,
    Object? totalIncome = null,
    Object? totalExpense = null,
    Object? transactionCount = null,
    Object? lastSyncTime = freezed,
  }) {
    return _then(_$UserStatsImpl(
      totalBalance: null == totalBalance
          ? _value.totalBalance
          : totalBalance // ignore: cast_nullable_to_non_nullable
              as double,
      totalIncome: null == totalIncome
          ? _value.totalIncome
          : totalIncome // ignore: cast_nullable_to_non_nullable
              as double,
      totalExpense: null == totalExpense
          ? _value.totalExpense
          : totalExpense // ignore: cast_nullable_to_non_nullable
              as double,
      transactionCount: null == transactionCount
          ? _value.transactionCount
          : transactionCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastSyncTime: freezed == lastSyncTime
          ? _value.lastSyncTime
          : lastSyncTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserStatsImpl implements _UserStats {
  const _$UserStatsImpl(
      {@HiveField(0) this.totalBalance = 0,
      @HiveField(1) this.totalIncome = 0,
      @HiveField(2) this.totalExpense = 0,
      @HiveField(3) this.transactionCount = 0,
      @HiveField(4) this.lastSyncTime});

  factory _$UserStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserStatsImplFromJson(json);

  @override
  @JsonKey()
  @HiveField(0)
  final double totalBalance;
  @override
  @JsonKey()
  @HiveField(1)
  final double totalIncome;
  @override
  @JsonKey()
  @HiveField(2)
  final double totalExpense;
  @override
  @JsonKey()
  @HiveField(3)
  final int transactionCount;
  @override
  @HiveField(4)
  final DateTime? lastSyncTime;

  @override
  String toString() {
    return 'UserStats(totalBalance: $totalBalance, totalIncome: $totalIncome, totalExpense: $totalExpense, transactionCount: $transactionCount, lastSyncTime: $lastSyncTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserStatsImpl &&
            (identical(other.totalBalance, totalBalance) ||
                other.totalBalance == totalBalance) &&
            (identical(other.totalIncome, totalIncome) ||
                other.totalIncome == totalIncome) &&
            (identical(other.totalExpense, totalExpense) ||
                other.totalExpense == totalExpense) &&
            (identical(other.transactionCount, transactionCount) ||
                other.transactionCount == transactionCount) &&
            (identical(other.lastSyncTime, lastSyncTime) ||
                other.lastSyncTime == lastSyncTime));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, totalBalance, totalIncome,
      totalExpense, transactionCount, lastSyncTime);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserStatsImplCopyWith<_$UserStatsImpl> get copyWith =>
      __$$UserStatsImplCopyWithImpl<_$UserStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserStatsImplToJson(
      this,
    );
  }
}

abstract class _UserStats implements UserStats {
  const factory _UserStats(
      {@HiveField(0) final double totalBalance,
      @HiveField(1) final double totalIncome,
      @HiveField(2) final double totalExpense,
      @HiveField(3) final int transactionCount,
      @HiveField(4) final DateTime? lastSyncTime}) = _$UserStatsImpl;

  factory _UserStats.fromJson(Map<String, dynamic> json) =
      _$UserStatsImpl.fromJson;

  @override
  @HiveField(0)
  double get totalBalance;
  @override
  @HiveField(1)
  double get totalIncome;
  @override
  @HiveField(2)
  double get totalExpense;
  @override
  @HiveField(3)
  int get transactionCount;
  @override
  @HiveField(4)
  DateTime? get lastSyncTime;
  @override
  @JsonKey(ignore: true)
  _$$UserStatsImplCopyWith<_$UserStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
