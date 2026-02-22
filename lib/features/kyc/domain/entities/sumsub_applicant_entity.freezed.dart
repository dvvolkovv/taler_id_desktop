// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sumsub_applicant_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SumsubApplicantEntity _$SumsubApplicantEntityFromJson(
    Map<String, dynamic> json) {
  return _SumsubApplicantEntity.fromJson(json);
}

/// @nodoc
mixin _$SumsubApplicantEntity {
  String get applicantId => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;
  String? get reviewStatus => throw _privateConstructorUsedError;
  SumsubReviewResult? get reviewResult => throw _privateConstructorUsedError;
  SumsubPersonInfo? get info => throw _privateConstructorUsedError;
  List<SumsubAddress> get addresses => throw _privateConstructorUsedError;
  List<SumsubIdDoc> get idDocs => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SumsubApplicantEntityCopyWith<SumsubApplicantEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SumsubApplicantEntityCopyWith<$Res> {
  factory $SumsubApplicantEntityCopyWith(SumsubApplicantEntity value,
          $Res Function(SumsubApplicantEntity) then) =
      _$SumsubApplicantEntityCopyWithImpl<$Res, SumsubApplicantEntity>;
  @useResult
  $Res call(
      {String applicantId,
      String? createdAt,
      String? reviewStatus,
      SumsubReviewResult? reviewResult,
      SumsubPersonInfo? info,
      List<SumsubAddress> addresses,
      List<SumsubIdDoc> idDocs});

  $SumsubReviewResultCopyWith<$Res>? get reviewResult;
  $SumsubPersonInfoCopyWith<$Res>? get info;
}

/// @nodoc
class _$SumsubApplicantEntityCopyWithImpl<$Res,
        $Val extends SumsubApplicantEntity>
    implements $SumsubApplicantEntityCopyWith<$Res> {
  _$SumsubApplicantEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? applicantId = null,
    Object? createdAt = freezed,
    Object? reviewStatus = freezed,
    Object? reviewResult = freezed,
    Object? info = freezed,
    Object? addresses = null,
    Object? idDocs = null,
  }) {
    return _then(_value.copyWith(
      applicantId: null == applicantId
          ? _value.applicantId
          : applicantId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      reviewStatus: freezed == reviewStatus
          ? _value.reviewStatus
          : reviewStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      reviewResult: freezed == reviewResult
          ? _value.reviewResult
          : reviewResult // ignore: cast_nullable_to_non_nullable
              as SumsubReviewResult?,
      info: freezed == info
          ? _value.info
          : info // ignore: cast_nullable_to_non_nullable
              as SumsubPersonInfo?,
      addresses: null == addresses
          ? _value.addresses
          : addresses // ignore: cast_nullable_to_non_nullable
              as List<SumsubAddress>,
      idDocs: null == idDocs
          ? _value.idDocs
          : idDocs // ignore: cast_nullable_to_non_nullable
              as List<SumsubIdDoc>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $SumsubReviewResultCopyWith<$Res>? get reviewResult {
    if (_value.reviewResult == null) {
      return null;
    }

    return $SumsubReviewResultCopyWith<$Res>(_value.reviewResult!, (value) {
      return _then(_value.copyWith(reviewResult: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $SumsubPersonInfoCopyWith<$Res>? get info {
    if (_value.info == null) {
      return null;
    }

    return $SumsubPersonInfoCopyWith<$Res>(_value.info!, (value) {
      return _then(_value.copyWith(info: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SumsubApplicantEntityImplCopyWith<$Res>
    implements $SumsubApplicantEntityCopyWith<$Res> {
  factory _$$SumsubApplicantEntityImplCopyWith(
          _$SumsubApplicantEntityImpl value,
          $Res Function(_$SumsubApplicantEntityImpl) then) =
      __$$SumsubApplicantEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String applicantId,
      String? createdAt,
      String? reviewStatus,
      SumsubReviewResult? reviewResult,
      SumsubPersonInfo? info,
      List<SumsubAddress> addresses,
      List<SumsubIdDoc> idDocs});

  @override
  $SumsubReviewResultCopyWith<$Res>? get reviewResult;
  @override
  $SumsubPersonInfoCopyWith<$Res>? get info;
}

/// @nodoc
class __$$SumsubApplicantEntityImplCopyWithImpl<$Res>
    extends _$SumsubApplicantEntityCopyWithImpl<$Res,
        _$SumsubApplicantEntityImpl>
    implements _$$SumsubApplicantEntityImplCopyWith<$Res> {
  __$$SumsubApplicantEntityImplCopyWithImpl(_$SumsubApplicantEntityImpl _value,
      $Res Function(_$SumsubApplicantEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? applicantId = null,
    Object? createdAt = freezed,
    Object? reviewStatus = freezed,
    Object? reviewResult = freezed,
    Object? info = freezed,
    Object? addresses = null,
    Object? idDocs = null,
  }) {
    return _then(_$SumsubApplicantEntityImpl(
      applicantId: null == applicantId
          ? _value.applicantId
          : applicantId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      reviewStatus: freezed == reviewStatus
          ? _value.reviewStatus
          : reviewStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      reviewResult: freezed == reviewResult
          ? _value.reviewResult
          : reviewResult // ignore: cast_nullable_to_non_nullable
              as SumsubReviewResult?,
      info: freezed == info
          ? _value.info
          : info // ignore: cast_nullable_to_non_nullable
              as SumsubPersonInfo?,
      addresses: null == addresses
          ? _value._addresses
          : addresses // ignore: cast_nullable_to_non_nullable
              as List<SumsubAddress>,
      idDocs: null == idDocs
          ? _value._idDocs
          : idDocs // ignore: cast_nullable_to_non_nullable
              as List<SumsubIdDoc>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SumsubApplicantEntityImpl implements _SumsubApplicantEntity {
  const _$SumsubApplicantEntityImpl(
      {required this.applicantId,
      this.createdAt,
      this.reviewStatus,
      this.reviewResult,
      this.info,
      final List<SumsubAddress> addresses = const [],
      final List<SumsubIdDoc> idDocs = const []})
      : _addresses = addresses,
        _idDocs = idDocs;

  factory _$SumsubApplicantEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$SumsubApplicantEntityImplFromJson(json);

  @override
  final String applicantId;
  @override
  final String? createdAt;
  @override
  final String? reviewStatus;
  @override
  final SumsubReviewResult? reviewResult;
  @override
  final SumsubPersonInfo? info;
  final List<SumsubAddress> _addresses;
  @override
  @JsonKey()
  List<SumsubAddress> get addresses {
    if (_addresses is EqualUnmodifiableListView) return _addresses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_addresses);
  }

  final List<SumsubIdDoc> _idDocs;
  @override
  @JsonKey()
  List<SumsubIdDoc> get idDocs {
    if (_idDocs is EqualUnmodifiableListView) return _idDocs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_idDocs);
  }

  @override
  String toString() {
    return 'SumsubApplicantEntity(applicantId: $applicantId, createdAt: $createdAt, reviewStatus: $reviewStatus, reviewResult: $reviewResult, info: $info, addresses: $addresses, idDocs: $idDocs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SumsubApplicantEntityImpl &&
            (identical(other.applicantId, applicantId) ||
                other.applicantId == applicantId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.reviewStatus, reviewStatus) ||
                other.reviewStatus == reviewStatus) &&
            (identical(other.reviewResult, reviewResult) ||
                other.reviewResult == reviewResult) &&
            (identical(other.info, info) || other.info == info) &&
            const DeepCollectionEquality()
                .equals(other._addresses, _addresses) &&
            const DeepCollectionEquality().equals(other._idDocs, _idDocs));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      applicantId,
      createdAt,
      reviewStatus,
      reviewResult,
      info,
      const DeepCollectionEquality().hash(_addresses),
      const DeepCollectionEquality().hash(_idDocs));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SumsubApplicantEntityImplCopyWith<_$SumsubApplicantEntityImpl>
      get copyWith => __$$SumsubApplicantEntityImplCopyWithImpl<
          _$SumsubApplicantEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SumsubApplicantEntityImplToJson(
      this,
    );
  }
}

abstract class _SumsubApplicantEntity implements SumsubApplicantEntity {
  const factory _SumsubApplicantEntity(
      {required final String applicantId,
      final String? createdAt,
      final String? reviewStatus,
      final SumsubReviewResult? reviewResult,
      final SumsubPersonInfo? info,
      final List<SumsubAddress> addresses,
      final List<SumsubIdDoc> idDocs}) = _$SumsubApplicantEntityImpl;

  factory _SumsubApplicantEntity.fromJson(Map<String, dynamic> json) =
      _$SumsubApplicantEntityImpl.fromJson;

  @override
  String get applicantId;
  @override
  String? get createdAt;
  @override
  String? get reviewStatus;
  @override
  SumsubReviewResult? get reviewResult;
  @override
  SumsubPersonInfo? get info;
  @override
  List<SumsubAddress> get addresses;
  @override
  List<SumsubIdDoc> get idDocs;
  @override
  @JsonKey(ignore: true)
  _$$SumsubApplicantEntityImplCopyWith<_$SumsubApplicantEntityImpl>
      get copyWith => throw _privateConstructorUsedError;
}

SumsubReviewResult _$SumsubReviewResultFromJson(Map<String, dynamic> json) {
  return _SumsubReviewResult.fromJson(json);
}

/// @nodoc
mixin _$SumsubReviewResult {
  String? get reviewAnswer => throw _privateConstructorUsedError;
  List<String> get rejectLabels => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SumsubReviewResultCopyWith<SumsubReviewResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SumsubReviewResultCopyWith<$Res> {
  factory $SumsubReviewResultCopyWith(
          SumsubReviewResult value, $Res Function(SumsubReviewResult) then) =
      _$SumsubReviewResultCopyWithImpl<$Res, SumsubReviewResult>;
  @useResult
  $Res call({String? reviewAnswer, List<String> rejectLabels});
}

/// @nodoc
class _$SumsubReviewResultCopyWithImpl<$Res, $Val extends SumsubReviewResult>
    implements $SumsubReviewResultCopyWith<$Res> {
  _$SumsubReviewResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reviewAnswer = freezed,
    Object? rejectLabels = null,
  }) {
    return _then(_value.copyWith(
      reviewAnswer: freezed == reviewAnswer
          ? _value.reviewAnswer
          : reviewAnswer // ignore: cast_nullable_to_non_nullable
              as String?,
      rejectLabels: null == rejectLabels
          ? _value.rejectLabels
          : rejectLabels // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SumsubReviewResultImplCopyWith<$Res>
    implements $SumsubReviewResultCopyWith<$Res> {
  factory _$$SumsubReviewResultImplCopyWith(_$SumsubReviewResultImpl value,
          $Res Function(_$SumsubReviewResultImpl) then) =
      __$$SumsubReviewResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? reviewAnswer, List<String> rejectLabels});
}

/// @nodoc
class __$$SumsubReviewResultImplCopyWithImpl<$Res>
    extends _$SumsubReviewResultCopyWithImpl<$Res, _$SumsubReviewResultImpl>
    implements _$$SumsubReviewResultImplCopyWith<$Res> {
  __$$SumsubReviewResultImplCopyWithImpl(_$SumsubReviewResultImpl _value,
      $Res Function(_$SumsubReviewResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reviewAnswer = freezed,
    Object? rejectLabels = null,
  }) {
    return _then(_$SumsubReviewResultImpl(
      reviewAnswer: freezed == reviewAnswer
          ? _value.reviewAnswer
          : reviewAnswer // ignore: cast_nullable_to_non_nullable
              as String?,
      rejectLabels: null == rejectLabels
          ? _value._rejectLabels
          : rejectLabels // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SumsubReviewResultImpl implements _SumsubReviewResult {
  const _$SumsubReviewResultImpl(
      {this.reviewAnswer, final List<String> rejectLabels = const []})
      : _rejectLabels = rejectLabels;

  factory _$SumsubReviewResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$SumsubReviewResultImplFromJson(json);

  @override
  final String? reviewAnswer;
  final List<String> _rejectLabels;
  @override
  @JsonKey()
  List<String> get rejectLabels {
    if (_rejectLabels is EqualUnmodifiableListView) return _rejectLabels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rejectLabels);
  }

  @override
  String toString() {
    return 'SumsubReviewResult(reviewAnswer: $reviewAnswer, rejectLabels: $rejectLabels)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SumsubReviewResultImpl &&
            (identical(other.reviewAnswer, reviewAnswer) ||
                other.reviewAnswer == reviewAnswer) &&
            const DeepCollectionEquality()
                .equals(other._rejectLabels, _rejectLabels));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, reviewAnswer,
      const DeepCollectionEquality().hash(_rejectLabels));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SumsubReviewResultImplCopyWith<_$SumsubReviewResultImpl> get copyWith =>
      __$$SumsubReviewResultImplCopyWithImpl<_$SumsubReviewResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SumsubReviewResultImplToJson(
      this,
    );
  }
}

abstract class _SumsubReviewResult implements SumsubReviewResult {
  const factory _SumsubReviewResult(
      {final String? reviewAnswer,
      final List<String> rejectLabels}) = _$SumsubReviewResultImpl;

  factory _SumsubReviewResult.fromJson(Map<String, dynamic> json) =
      _$SumsubReviewResultImpl.fromJson;

  @override
  String? get reviewAnswer;
  @override
  List<String> get rejectLabels;
  @override
  @JsonKey(ignore: true)
  _$$SumsubReviewResultImplCopyWith<_$SumsubReviewResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SumsubPersonInfo _$SumsubPersonInfoFromJson(Map<String, dynamic> json) {
  return _SumsubPersonInfo.fromJson(json);
}

/// @nodoc
mixin _$SumsubPersonInfo {
  String? get firstName => throw _privateConstructorUsedError;
  String? get lastName => throw _privateConstructorUsedError;
  String? get middleName => throw _privateConstructorUsedError;
  String? get dob => throw _privateConstructorUsedError;
  String? get placeOfBirth => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;
  String? get nationality => throw _privateConstructorUsedError;
  String? get gender => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SumsubPersonInfoCopyWith<SumsubPersonInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SumsubPersonInfoCopyWith<$Res> {
  factory $SumsubPersonInfoCopyWith(
          SumsubPersonInfo value, $Res Function(SumsubPersonInfo) then) =
      _$SumsubPersonInfoCopyWithImpl<$Res, SumsubPersonInfo>;
  @useResult
  $Res call(
      {String? firstName,
      String? lastName,
      String? middleName,
      String? dob,
      String? placeOfBirth,
      String? country,
      String? nationality,
      String? gender});
}

/// @nodoc
class _$SumsubPersonInfoCopyWithImpl<$Res, $Val extends SumsubPersonInfo>
    implements $SumsubPersonInfoCopyWith<$Res> {
  _$SumsubPersonInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? middleName = freezed,
    Object? dob = freezed,
    Object? placeOfBirth = freezed,
    Object? country = freezed,
    Object? nationality = freezed,
    Object? gender = freezed,
  }) {
    return _then(_value.copyWith(
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      middleName: freezed == middleName
          ? _value.middleName
          : middleName // ignore: cast_nullable_to_non_nullable
              as String?,
      dob: freezed == dob
          ? _value.dob
          : dob // ignore: cast_nullable_to_non_nullable
              as String?,
      placeOfBirth: freezed == placeOfBirth
          ? _value.placeOfBirth
          : placeOfBirth // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      nationality: freezed == nationality
          ? _value.nationality
          : nationality // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SumsubPersonInfoImplCopyWith<$Res>
    implements $SumsubPersonInfoCopyWith<$Res> {
  factory _$$SumsubPersonInfoImplCopyWith(_$SumsubPersonInfoImpl value,
          $Res Function(_$SumsubPersonInfoImpl) then) =
      __$$SumsubPersonInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? firstName,
      String? lastName,
      String? middleName,
      String? dob,
      String? placeOfBirth,
      String? country,
      String? nationality,
      String? gender});
}

/// @nodoc
class __$$SumsubPersonInfoImplCopyWithImpl<$Res>
    extends _$SumsubPersonInfoCopyWithImpl<$Res, _$SumsubPersonInfoImpl>
    implements _$$SumsubPersonInfoImplCopyWith<$Res> {
  __$$SumsubPersonInfoImplCopyWithImpl(_$SumsubPersonInfoImpl _value,
      $Res Function(_$SumsubPersonInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? middleName = freezed,
    Object? dob = freezed,
    Object? placeOfBirth = freezed,
    Object? country = freezed,
    Object? nationality = freezed,
    Object? gender = freezed,
  }) {
    return _then(_$SumsubPersonInfoImpl(
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      middleName: freezed == middleName
          ? _value.middleName
          : middleName // ignore: cast_nullable_to_non_nullable
              as String?,
      dob: freezed == dob
          ? _value.dob
          : dob // ignore: cast_nullable_to_non_nullable
              as String?,
      placeOfBirth: freezed == placeOfBirth
          ? _value.placeOfBirth
          : placeOfBirth // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      nationality: freezed == nationality
          ? _value.nationality
          : nationality // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SumsubPersonInfoImpl implements _SumsubPersonInfo {
  const _$SumsubPersonInfoImpl(
      {this.firstName,
      this.lastName,
      this.middleName,
      this.dob,
      this.placeOfBirth,
      this.country,
      this.nationality,
      this.gender});

  factory _$SumsubPersonInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SumsubPersonInfoImplFromJson(json);

  @override
  final String? firstName;
  @override
  final String? lastName;
  @override
  final String? middleName;
  @override
  final String? dob;
  @override
  final String? placeOfBirth;
  @override
  final String? country;
  @override
  final String? nationality;
  @override
  final String? gender;

  @override
  String toString() {
    return 'SumsubPersonInfo(firstName: $firstName, lastName: $lastName, middleName: $middleName, dob: $dob, placeOfBirth: $placeOfBirth, country: $country, nationality: $nationality, gender: $gender)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SumsubPersonInfoImpl &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.middleName, middleName) ||
                other.middleName == middleName) &&
            (identical(other.dob, dob) || other.dob == dob) &&
            (identical(other.placeOfBirth, placeOfBirth) ||
                other.placeOfBirth == placeOfBirth) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.nationality, nationality) ||
                other.nationality == nationality) &&
            (identical(other.gender, gender) || other.gender == gender));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, firstName, lastName, middleName,
      dob, placeOfBirth, country, nationality, gender);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SumsubPersonInfoImplCopyWith<_$SumsubPersonInfoImpl> get copyWith =>
      __$$SumsubPersonInfoImplCopyWithImpl<_$SumsubPersonInfoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SumsubPersonInfoImplToJson(
      this,
    );
  }
}

abstract class _SumsubPersonInfo implements SumsubPersonInfo {
  const factory _SumsubPersonInfo(
      {final String? firstName,
      final String? lastName,
      final String? middleName,
      final String? dob,
      final String? placeOfBirth,
      final String? country,
      final String? nationality,
      final String? gender}) = _$SumsubPersonInfoImpl;

  factory _SumsubPersonInfo.fromJson(Map<String, dynamic> json) =
      _$SumsubPersonInfoImpl.fromJson;

  @override
  String? get firstName;
  @override
  String? get lastName;
  @override
  String? get middleName;
  @override
  String? get dob;
  @override
  String? get placeOfBirth;
  @override
  String? get country;
  @override
  String? get nationality;
  @override
  String? get gender;
  @override
  @JsonKey(ignore: true)
  _$$SumsubPersonInfoImplCopyWith<_$SumsubPersonInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SumsubAddress _$SumsubAddressFromJson(Map<String, dynamic> json) {
  return _SumsubAddress.fromJson(json);
}

/// @nodoc
mixin _$SumsubAddress {
  String? get street => throw _privateConstructorUsedError;
  String? get buildingNumber => throw _privateConstructorUsedError;
  String? get flatNumber => throw _privateConstructorUsedError;
  String? get town => throw _privateConstructorUsedError;
  String? get state => throw _privateConstructorUsedError;
  String? get postCode => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SumsubAddressCopyWith<SumsubAddress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SumsubAddressCopyWith<$Res> {
  factory $SumsubAddressCopyWith(
          SumsubAddress value, $Res Function(SumsubAddress) then) =
      _$SumsubAddressCopyWithImpl<$Res, SumsubAddress>;
  @useResult
  $Res call(
      {String? street,
      String? buildingNumber,
      String? flatNumber,
      String? town,
      String? state,
      String? postCode,
      String? country});
}

/// @nodoc
class _$SumsubAddressCopyWithImpl<$Res, $Val extends SumsubAddress>
    implements $SumsubAddressCopyWith<$Res> {
  _$SumsubAddressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? street = freezed,
    Object? buildingNumber = freezed,
    Object? flatNumber = freezed,
    Object? town = freezed,
    Object? state = freezed,
    Object? postCode = freezed,
    Object? country = freezed,
  }) {
    return _then(_value.copyWith(
      street: freezed == street
          ? _value.street
          : street // ignore: cast_nullable_to_non_nullable
              as String?,
      buildingNumber: freezed == buildingNumber
          ? _value.buildingNumber
          : buildingNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      flatNumber: freezed == flatNumber
          ? _value.flatNumber
          : flatNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      town: freezed == town
          ? _value.town
          : town // ignore: cast_nullable_to_non_nullable
              as String?,
      state: freezed == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String?,
      postCode: freezed == postCode
          ? _value.postCode
          : postCode // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SumsubAddressImplCopyWith<$Res>
    implements $SumsubAddressCopyWith<$Res> {
  factory _$$SumsubAddressImplCopyWith(
          _$SumsubAddressImpl value, $Res Function(_$SumsubAddressImpl) then) =
      __$$SumsubAddressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? street,
      String? buildingNumber,
      String? flatNumber,
      String? town,
      String? state,
      String? postCode,
      String? country});
}

/// @nodoc
class __$$SumsubAddressImplCopyWithImpl<$Res>
    extends _$SumsubAddressCopyWithImpl<$Res, _$SumsubAddressImpl>
    implements _$$SumsubAddressImplCopyWith<$Res> {
  __$$SumsubAddressImplCopyWithImpl(
      _$SumsubAddressImpl _value, $Res Function(_$SumsubAddressImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? street = freezed,
    Object? buildingNumber = freezed,
    Object? flatNumber = freezed,
    Object? town = freezed,
    Object? state = freezed,
    Object? postCode = freezed,
    Object? country = freezed,
  }) {
    return _then(_$SumsubAddressImpl(
      street: freezed == street
          ? _value.street
          : street // ignore: cast_nullable_to_non_nullable
              as String?,
      buildingNumber: freezed == buildingNumber
          ? _value.buildingNumber
          : buildingNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      flatNumber: freezed == flatNumber
          ? _value.flatNumber
          : flatNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      town: freezed == town
          ? _value.town
          : town // ignore: cast_nullable_to_non_nullable
              as String?,
      state: freezed == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String?,
      postCode: freezed == postCode
          ? _value.postCode
          : postCode // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SumsubAddressImpl implements _SumsubAddress {
  const _$SumsubAddressImpl(
      {this.street,
      this.buildingNumber,
      this.flatNumber,
      this.town,
      this.state,
      this.postCode,
      this.country});

  factory _$SumsubAddressImpl.fromJson(Map<String, dynamic> json) =>
      _$$SumsubAddressImplFromJson(json);

  @override
  final String? street;
  @override
  final String? buildingNumber;
  @override
  final String? flatNumber;
  @override
  final String? town;
  @override
  final String? state;
  @override
  final String? postCode;
  @override
  final String? country;

  @override
  String toString() {
    return 'SumsubAddress(street: $street, buildingNumber: $buildingNumber, flatNumber: $flatNumber, town: $town, state: $state, postCode: $postCode, country: $country)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SumsubAddressImpl &&
            (identical(other.street, street) || other.street == street) &&
            (identical(other.buildingNumber, buildingNumber) ||
                other.buildingNumber == buildingNumber) &&
            (identical(other.flatNumber, flatNumber) ||
                other.flatNumber == flatNumber) &&
            (identical(other.town, town) || other.town == town) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.postCode, postCode) ||
                other.postCode == postCode) &&
            (identical(other.country, country) || other.country == country));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, street, buildingNumber,
      flatNumber, town, state, postCode, country);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SumsubAddressImplCopyWith<_$SumsubAddressImpl> get copyWith =>
      __$$SumsubAddressImplCopyWithImpl<_$SumsubAddressImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SumsubAddressImplToJson(
      this,
    );
  }
}

abstract class _SumsubAddress implements SumsubAddress {
  const factory _SumsubAddress(
      {final String? street,
      final String? buildingNumber,
      final String? flatNumber,
      final String? town,
      final String? state,
      final String? postCode,
      final String? country}) = _$SumsubAddressImpl;

  factory _SumsubAddress.fromJson(Map<String, dynamic> json) =
      _$SumsubAddressImpl.fromJson;

  @override
  String? get street;
  @override
  String? get buildingNumber;
  @override
  String? get flatNumber;
  @override
  String? get town;
  @override
  String? get state;
  @override
  String? get postCode;
  @override
  String? get country;
  @override
  @JsonKey(ignore: true)
  _$$SumsubAddressImplCopyWith<_$SumsubAddressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SumsubIdDoc _$SumsubIdDocFromJson(Map<String, dynamic> json) {
  return _SumsubIdDoc.fromJson(json);
}

/// @nodoc
mixin _$SumsubIdDoc {
  String? get idDocType => throw _privateConstructorUsedError;
  String? get number => throw _privateConstructorUsedError;
  String? get firstName => throw _privateConstructorUsedError;
  String? get lastName => throw _privateConstructorUsedError;
  String? get issuedDate => throw _privateConstructorUsedError;
  String? get validUntil => throw _privateConstructorUsedError;
  String? get issuedBy => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SumsubIdDocCopyWith<SumsubIdDoc> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SumsubIdDocCopyWith<$Res> {
  factory $SumsubIdDocCopyWith(
          SumsubIdDoc value, $Res Function(SumsubIdDoc) then) =
      _$SumsubIdDocCopyWithImpl<$Res, SumsubIdDoc>;
  @useResult
  $Res call(
      {String? idDocType,
      String? number,
      String? firstName,
      String? lastName,
      String? issuedDate,
      String? validUntil,
      String? issuedBy,
      String? country});
}

/// @nodoc
class _$SumsubIdDocCopyWithImpl<$Res, $Val extends SumsubIdDoc>
    implements $SumsubIdDocCopyWith<$Res> {
  _$SumsubIdDocCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idDocType = freezed,
    Object? number = freezed,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? issuedDate = freezed,
    Object? validUntil = freezed,
    Object? issuedBy = freezed,
    Object? country = freezed,
  }) {
    return _then(_value.copyWith(
      idDocType: freezed == idDocType
          ? _value.idDocType
          : idDocType // ignore: cast_nullable_to_non_nullable
              as String?,
      number: freezed == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as String?,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      issuedDate: freezed == issuedDate
          ? _value.issuedDate
          : issuedDate // ignore: cast_nullable_to_non_nullable
              as String?,
      validUntil: freezed == validUntil
          ? _value.validUntil
          : validUntil // ignore: cast_nullable_to_non_nullable
              as String?,
      issuedBy: freezed == issuedBy
          ? _value.issuedBy
          : issuedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SumsubIdDocImplCopyWith<$Res>
    implements $SumsubIdDocCopyWith<$Res> {
  factory _$$SumsubIdDocImplCopyWith(
          _$SumsubIdDocImpl value, $Res Function(_$SumsubIdDocImpl) then) =
      __$$SumsubIdDocImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? idDocType,
      String? number,
      String? firstName,
      String? lastName,
      String? issuedDate,
      String? validUntil,
      String? issuedBy,
      String? country});
}

/// @nodoc
class __$$SumsubIdDocImplCopyWithImpl<$Res>
    extends _$SumsubIdDocCopyWithImpl<$Res, _$SumsubIdDocImpl>
    implements _$$SumsubIdDocImplCopyWith<$Res> {
  __$$SumsubIdDocImplCopyWithImpl(
      _$SumsubIdDocImpl _value, $Res Function(_$SumsubIdDocImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idDocType = freezed,
    Object? number = freezed,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? issuedDate = freezed,
    Object? validUntil = freezed,
    Object? issuedBy = freezed,
    Object? country = freezed,
  }) {
    return _then(_$SumsubIdDocImpl(
      idDocType: freezed == idDocType
          ? _value.idDocType
          : idDocType // ignore: cast_nullable_to_non_nullable
              as String?,
      number: freezed == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as String?,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      issuedDate: freezed == issuedDate
          ? _value.issuedDate
          : issuedDate // ignore: cast_nullable_to_non_nullable
              as String?,
      validUntil: freezed == validUntil
          ? _value.validUntil
          : validUntil // ignore: cast_nullable_to_non_nullable
              as String?,
      issuedBy: freezed == issuedBy
          ? _value.issuedBy
          : issuedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SumsubIdDocImpl implements _SumsubIdDoc {
  const _$SumsubIdDocImpl(
      {this.idDocType,
      this.number,
      this.firstName,
      this.lastName,
      this.issuedDate,
      this.validUntil,
      this.issuedBy,
      this.country});

  factory _$SumsubIdDocImpl.fromJson(Map<String, dynamic> json) =>
      _$$SumsubIdDocImplFromJson(json);

  @override
  final String? idDocType;
  @override
  final String? number;
  @override
  final String? firstName;
  @override
  final String? lastName;
  @override
  final String? issuedDate;
  @override
  final String? validUntil;
  @override
  final String? issuedBy;
  @override
  final String? country;

  @override
  String toString() {
    return 'SumsubIdDoc(idDocType: $idDocType, number: $number, firstName: $firstName, lastName: $lastName, issuedDate: $issuedDate, validUntil: $validUntil, issuedBy: $issuedBy, country: $country)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SumsubIdDocImpl &&
            (identical(other.idDocType, idDocType) ||
                other.idDocType == idDocType) &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.issuedDate, issuedDate) ||
                other.issuedDate == issuedDate) &&
            (identical(other.validUntil, validUntil) ||
                other.validUntil == validUntil) &&
            (identical(other.issuedBy, issuedBy) ||
                other.issuedBy == issuedBy) &&
            (identical(other.country, country) || other.country == country));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, idDocType, number, firstName,
      lastName, issuedDate, validUntil, issuedBy, country);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SumsubIdDocImplCopyWith<_$SumsubIdDocImpl> get copyWith =>
      __$$SumsubIdDocImplCopyWithImpl<_$SumsubIdDocImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SumsubIdDocImplToJson(
      this,
    );
  }
}

abstract class _SumsubIdDoc implements SumsubIdDoc {
  const factory _SumsubIdDoc(
      {final String? idDocType,
      final String? number,
      final String? firstName,
      final String? lastName,
      final String? issuedDate,
      final String? validUntil,
      final String? issuedBy,
      final String? country}) = _$SumsubIdDocImpl;

  factory _SumsubIdDoc.fromJson(Map<String, dynamic> json) =
      _$SumsubIdDocImpl.fromJson;

  @override
  String? get idDocType;
  @override
  String? get number;
  @override
  String? get firstName;
  @override
  String? get lastName;
  @override
  String? get issuedDate;
  @override
  String? get validUntil;
  @override
  String? get issuedBy;
  @override
  String? get country;
  @override
  @JsonKey(ignore: true)
  _$$SumsubIdDocImplCopyWith<_$SumsubIdDocImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
