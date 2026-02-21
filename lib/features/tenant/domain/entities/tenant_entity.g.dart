// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TenantEntityImpl _$$TenantEntityImplFromJson(Map<String, dynamic> json) =>
    _$TenantEntityImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      website: json['website'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      kybStatus: $enumDecodeNullable(_$KybStatusEnumMap, json['kybStatus']) ??
          KybStatus.none,
      myRole: $enumDecodeNullable(_$TenantRoleEnumMap, json['myRole']),
      members: (json['members'] as List<dynamic>?)
              ?.map(
                  (e) => TenantMemberEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$TenantEntityImplToJson(_$TenantEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'logoUrl': instance.logoUrl,
      'website': instance.website,
      'email': instance.email,
      'phone': instance.phone,
      'address': instance.address,
      'kybStatus': _$KybStatusEnumMap[instance.kybStatus]!,
      'myRole': _$TenantRoleEnumMap[instance.myRole],
      'members': instance.members,
    };

const _$KybStatusEnumMap = {
  KybStatus.none: 'UNVERIFIED',
  KybStatus.pending: 'PENDING',
  KybStatus.verified: 'VERIFIED',
  KybStatus.rejected: 'REJECTED',
};

const _$TenantRoleEnumMap = {
  TenantRole.owner: 'OWNER',
  TenantRole.admin: 'ADMIN',
  TenantRole.operator: 'OPERATOR',
  TenantRole.viewer: 'VIEWER',
};

_$TenantMemberEntityImpl _$$TenantMemberEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$TenantMemberEntityImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      role: $enumDecode(_$TenantRoleEnumMap, json['role']),
      userId: json['userId'] as String?,
    );

Map<String, dynamic> _$$TenantMemberEntityImplToJson(
        _$TenantMemberEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'role': _$TenantRoleEnumMap[instance.role]!,
      'userId': instance.userId,
    };
