// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GroupMemberEntityImpl _$$GroupMemberEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$GroupMemberEntityImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      role: json['role'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      joinedAt: json['joinedAt'] == null
          ? null
          : DateTime.parse(json['joinedAt'] as String),
    );

Map<String, dynamic> _$$GroupMemberEntityImplToJson(
        _$GroupMemberEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'role': instance.role,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'username': instance.username,
      'avatarUrl': instance.avatarUrl,
      'joinedAt': instance.joinedAt?.toIso8601String(),
    };
