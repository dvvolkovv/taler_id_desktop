// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_member_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GroupMemberEntity _$GroupMemberEntityFromJson(Map<String, dynamic> json) {
  return _GroupMemberEntity.fromJson(json);
}

/// @nodoc
mixin _$GroupMemberEntity {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  String? get firstName => throw _privateConstructorUsedError;
  String? get lastName => throw _privateConstructorUsedError;
  String? get username => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  DateTime? get joinedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GroupMemberEntityCopyWith<GroupMemberEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupMemberEntityCopyWith<$Res> {
  factory $GroupMemberEntityCopyWith(
          GroupMemberEntity value, $Res Function(GroupMemberEntity) then) =
      _$GroupMemberEntityCopyWithImpl<$Res, GroupMemberEntity>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String role,
      String? firstName,
      String? lastName,
      String? username,
      String? avatarUrl,
      DateTime? joinedAt});
}

/// @nodoc
class _$GroupMemberEntityCopyWithImpl<$Res, $Val extends GroupMemberEntity>
    implements $GroupMemberEntityCopyWith<$Res> {
  _$GroupMemberEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? role = null,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? username = freezed,
    Object? avatarUrl = freezed,
    Object? joinedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      joinedAt: freezed == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GroupMemberEntityImplCopyWith<$Res>
    implements $GroupMemberEntityCopyWith<$Res> {
  factory _$$GroupMemberEntityImplCopyWith(_$GroupMemberEntityImpl value,
          $Res Function(_$GroupMemberEntityImpl) then) =
      __$$GroupMemberEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String role,
      String? firstName,
      String? lastName,
      String? username,
      String? avatarUrl,
      DateTime? joinedAt});
}

/// @nodoc
class __$$GroupMemberEntityImplCopyWithImpl<$Res>
    extends _$GroupMemberEntityCopyWithImpl<$Res, _$GroupMemberEntityImpl>
    implements _$$GroupMemberEntityImplCopyWith<$Res> {
  __$$GroupMemberEntityImplCopyWithImpl(_$GroupMemberEntityImpl _value,
      $Res Function(_$GroupMemberEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? role = null,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? username = freezed,
    Object? avatarUrl = freezed,
    Object? joinedAt = freezed,
  }) {
    return _then(_$GroupMemberEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      joinedAt: freezed == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupMemberEntityImpl implements _GroupMemberEntity {
  const _$GroupMemberEntityImpl(
      {required this.id,
      required this.userId,
      required this.role,
      this.firstName,
      this.lastName,
      this.username,
      this.avatarUrl,
      this.joinedAt});

  factory _$GroupMemberEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupMemberEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String role;
  @override
  final String? firstName;
  @override
  final String? lastName;
  @override
  final String? username;
  @override
  final String? avatarUrl;
  @override
  final DateTime? joinedAt;

  @override
  String toString() {
    return 'GroupMemberEntity(id: $id, userId: $userId, role: $role, firstName: $firstName, lastName: $lastName, username: $username, avatarUrl: $avatarUrl, joinedAt: $joinedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupMemberEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, role, firstName,
      lastName, username, avatarUrl, joinedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupMemberEntityImplCopyWith<_$GroupMemberEntityImpl> get copyWith =>
      __$$GroupMemberEntityImplCopyWithImpl<_$GroupMemberEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupMemberEntityImplToJson(
      this,
    );
  }
}

abstract class _GroupMemberEntity implements GroupMemberEntity {
  const factory _GroupMemberEntity(
      {required final String id,
      required final String userId,
      required final String role,
      final String? firstName,
      final String? lastName,
      final String? username,
      final String? avatarUrl,
      final DateTime? joinedAt}) = _$GroupMemberEntityImpl;

  factory _GroupMemberEntity.fromJson(Map<String, dynamic> json) =
      _$GroupMemberEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get role;
  @override
  String? get firstName;
  @override
  String? get lastName;
  @override
  String? get username;
  @override
  String? get avatarUrl;
  @override
  DateTime? get joinedAt;
  @override
  @JsonKey(ignore: true)
  _$$GroupMemberEntityImplCopyWith<_$GroupMemberEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
