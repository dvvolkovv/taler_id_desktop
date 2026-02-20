// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tenant_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TenantEntity _$TenantEntityFromJson(Map<String, dynamic> json) {
  return _TenantEntity.fromJson(json);
}

/// @nodoc
mixin _$TenantEntity {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get logoUrl => throw _privateConstructorUsedError;
  String? get website => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  KybStatus get kybStatus => throw _privateConstructorUsedError;
  TenantRole? get myRole => throw _privateConstructorUsedError;
  List<TenantMemberEntity> get members => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TenantEntityCopyWith<TenantEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TenantEntityCopyWith<$Res> {
  factory $TenantEntityCopyWith(
          TenantEntity value, $Res Function(TenantEntity) then) =
      _$TenantEntityCopyWithImpl<$Res, TenantEntity>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? description,
      String? logoUrl,
      String? website,
      String? email,
      String? phone,
      String? address,
      KybStatus kybStatus,
      TenantRole? myRole,
      List<TenantMemberEntity> members});
}

/// @nodoc
class _$TenantEntityCopyWithImpl<$Res, $Val extends TenantEntity>
    implements $TenantEntityCopyWith<$Res> {
  _$TenantEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? logoUrl = freezed,
    Object? website = freezed,
    Object? email = freezed,
    Object? phone = freezed,
    Object? address = freezed,
    Object? kybStatus = null,
    Object? myRole = freezed,
    Object? members = null,
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
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      logoUrl: freezed == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      website: freezed == website
          ? _value.website
          : website // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      kybStatus: null == kybStatus
          ? _value.kybStatus
          : kybStatus // ignore: cast_nullable_to_non_nullable
              as KybStatus,
      myRole: freezed == myRole
          ? _value.myRole
          : myRole // ignore: cast_nullable_to_non_nullable
              as TenantRole?,
      members: null == members
          ? _value.members
          : members // ignore: cast_nullable_to_non_nullable
              as List<TenantMemberEntity>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TenantEntityImplCopyWith<$Res>
    implements $TenantEntityCopyWith<$Res> {
  factory _$$TenantEntityImplCopyWith(
          _$TenantEntityImpl value, $Res Function(_$TenantEntityImpl) then) =
      __$$TenantEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? description,
      String? logoUrl,
      String? website,
      String? email,
      String? phone,
      String? address,
      KybStatus kybStatus,
      TenantRole? myRole,
      List<TenantMemberEntity> members});
}

/// @nodoc
class __$$TenantEntityImplCopyWithImpl<$Res>
    extends _$TenantEntityCopyWithImpl<$Res, _$TenantEntityImpl>
    implements _$$TenantEntityImplCopyWith<$Res> {
  __$$TenantEntityImplCopyWithImpl(
      _$TenantEntityImpl _value, $Res Function(_$TenantEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? logoUrl = freezed,
    Object? website = freezed,
    Object? email = freezed,
    Object? phone = freezed,
    Object? address = freezed,
    Object? kybStatus = null,
    Object? myRole = freezed,
    Object? members = null,
  }) {
    return _then(_$TenantEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      logoUrl: freezed == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      website: freezed == website
          ? _value.website
          : website // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      kybStatus: null == kybStatus
          ? _value.kybStatus
          : kybStatus // ignore: cast_nullable_to_non_nullable
              as KybStatus,
      myRole: freezed == myRole
          ? _value.myRole
          : myRole // ignore: cast_nullable_to_non_nullable
              as TenantRole?,
      members: null == members
          ? _value._members
          : members // ignore: cast_nullable_to_non_nullable
              as List<TenantMemberEntity>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TenantEntityImpl implements _TenantEntity {
  const _$TenantEntityImpl(
      {required this.id,
      required this.name,
      this.description,
      this.logoUrl,
      this.website,
      this.email,
      this.phone,
      this.address,
      this.kybStatus = KybStatus.none,
      this.myRole,
      final List<TenantMemberEntity> members = const []})
      : _members = members;

  factory _$TenantEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$TenantEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String? logoUrl;
  @override
  final String? website;
  @override
  final String? email;
  @override
  final String? phone;
  @override
  final String? address;
  @override
  @JsonKey()
  final KybStatus kybStatus;
  @override
  final TenantRole? myRole;
  final List<TenantMemberEntity> _members;
  @override
  @JsonKey()
  List<TenantMemberEntity> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  @override
  String toString() {
    return 'TenantEntity(id: $id, name: $name, description: $description, logoUrl: $logoUrl, website: $website, email: $email, phone: $phone, address: $address, kybStatus: $kybStatus, myRole: $myRole, members: $members)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TenantEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.website, website) || other.website == website) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.kybStatus, kybStatus) ||
                other.kybStatus == kybStatus) &&
            (identical(other.myRole, myRole) || other.myRole == myRole) &&
            const DeepCollectionEquality().equals(other._members, _members));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      logoUrl,
      website,
      email,
      phone,
      address,
      kybStatus,
      myRole,
      const DeepCollectionEquality().hash(_members));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TenantEntityImplCopyWith<_$TenantEntityImpl> get copyWith =>
      __$$TenantEntityImplCopyWithImpl<_$TenantEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TenantEntityImplToJson(
      this,
    );
  }
}

abstract class _TenantEntity implements TenantEntity {
  const factory _TenantEntity(
      {required final String id,
      required final String name,
      final String? description,
      final String? logoUrl,
      final String? website,
      final String? email,
      final String? phone,
      final String? address,
      final KybStatus kybStatus,
      final TenantRole? myRole,
      final List<TenantMemberEntity> members}) = _$TenantEntityImpl;

  factory _TenantEntity.fromJson(Map<String, dynamic> json) =
      _$TenantEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  String? get logoUrl;
  @override
  String? get website;
  @override
  String? get email;
  @override
  String? get phone;
  @override
  String? get address;
  @override
  KybStatus get kybStatus;
  @override
  TenantRole? get myRole;
  @override
  List<TenantMemberEntity> get members;
  @override
  @JsonKey(ignore: true)
  _$$TenantEntityImplCopyWith<_$TenantEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TenantMemberEntity _$TenantMemberEntityFromJson(Map<String, dynamic> json) {
  return _TenantMemberEntity.fromJson(json);
}

/// @nodoc
mixin _$TenantMemberEntity {
  String get id => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String? get firstName => throw _privateConstructorUsedError;
  String? get lastName => throw _privateConstructorUsedError;
  TenantRole get role => throw _privateConstructorUsedError;
  String? get userId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TenantMemberEntityCopyWith<TenantMemberEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TenantMemberEntityCopyWith<$Res> {
  factory $TenantMemberEntityCopyWith(
          TenantMemberEntity value, $Res Function(TenantMemberEntity) then) =
      _$TenantMemberEntityCopyWithImpl<$Res, TenantMemberEntity>;
  @useResult
  $Res call(
      {String id,
      String email,
      String? firstName,
      String? lastName,
      TenantRole role,
      String? userId});
}

/// @nodoc
class _$TenantMemberEntityCopyWithImpl<$Res, $Val extends TenantMemberEntity>
    implements $TenantMemberEntityCopyWith<$Res> {
  _$TenantMemberEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? role = null,
    Object? userId = freezed,
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
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as TenantRole,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TenantMemberEntityImplCopyWith<$Res>
    implements $TenantMemberEntityCopyWith<$Res> {
  factory _$$TenantMemberEntityImplCopyWith(_$TenantMemberEntityImpl value,
          $Res Function(_$TenantMemberEntityImpl) then) =
      __$$TenantMemberEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String email,
      String? firstName,
      String? lastName,
      TenantRole role,
      String? userId});
}

/// @nodoc
class __$$TenantMemberEntityImplCopyWithImpl<$Res>
    extends _$TenantMemberEntityCopyWithImpl<$Res, _$TenantMemberEntityImpl>
    implements _$$TenantMemberEntityImplCopyWith<$Res> {
  __$$TenantMemberEntityImplCopyWithImpl(_$TenantMemberEntityImpl _value,
      $Res Function(_$TenantMemberEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? role = null,
    Object? userId = freezed,
  }) {
    return _then(_$TenantMemberEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as TenantRole,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TenantMemberEntityImpl implements _TenantMemberEntity {
  const _$TenantMemberEntityImpl(
      {required this.id,
      required this.email,
      this.firstName,
      this.lastName,
      required this.role,
      this.userId});

  factory _$TenantMemberEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$TenantMemberEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String email;
  @override
  final String? firstName;
  @override
  final String? lastName;
  @override
  final TenantRole role;
  @override
  final String? userId;

  @override
  String toString() {
    return 'TenantMemberEntity(id: $id, email: $email, firstName: $firstName, lastName: $lastName, role: $role, userId: $userId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TenantMemberEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.userId, userId) || other.userId == userId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, email, firstName, lastName, role, userId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TenantMemberEntityImplCopyWith<_$TenantMemberEntityImpl> get copyWith =>
      __$$TenantMemberEntityImplCopyWithImpl<_$TenantMemberEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TenantMemberEntityImplToJson(
      this,
    );
  }
}

abstract class _TenantMemberEntity implements TenantMemberEntity {
  const factory _TenantMemberEntity(
      {required final String id,
      required final String email,
      final String? firstName,
      final String? lastName,
      required final TenantRole role,
      final String? userId}) = _$TenantMemberEntityImpl;

  factory _TenantMemberEntity.fromJson(Map<String, dynamic> json) =
      _$TenantMemberEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get email;
  @override
  String? get firstName;
  @override
  String? get lastName;
  @override
  TenantRole get role;
  @override
  String? get userId;
  @override
  @JsonKey(ignore: true)
  _$$TenantMemberEntityImplCopyWith<_$TenantMemberEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
