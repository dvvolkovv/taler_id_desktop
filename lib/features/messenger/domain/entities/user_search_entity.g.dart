// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_search_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserSearchEntityImpl _$$UserSearchEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$UserSearchEntityImpl(
      id: json['id'] as String,
      username: json['username'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$$UserSearchEntityImplToJson(
        _$UserSearchEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'avatarUrl': instance.avatarUrl,
    };
