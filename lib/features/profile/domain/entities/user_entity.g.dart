// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserEntityImpl _$$UserEntityImplFromJson(Map<String, dynamic> json) =>
    _$UserEntityImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      country: json['country'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      postalCode: json['postalCode'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      kycStatus: $enumDecodeNullable(_$KycStatusEnumMap, json['kycStatus']) ??
          KycStatus.unverified,
      fcmToken: json['fcmToken'] as String?,
      documents: (json['documents'] as List<dynamic>?)
          ?.map((e) => DocumentEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$UserEntityImplToJson(_$UserEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'phone': instance.phone,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'country': instance.country,
      'avatarUrl': instance.avatarUrl,
      'postalCode': instance.postalCode,
      'dateOfBirth': instance.dateOfBirth,
      'kycStatus': _$KycStatusEnumMap[instance.kycStatus]!,
      'fcmToken': instance.fcmToken,
      'documents': instance.documents,
    };

const _$KycStatusEnumMap = {
  KycStatus.unverified: 'UNVERIFIED',
  KycStatus.pending: 'PENDING',
  KycStatus.verified: 'VERIFIED',
  KycStatus.rejected: 'REJECTED',
};

_$DocumentEntityImpl _$$DocumentEntityImplFromJson(Map<String, dynamic> json) =>
    _$DocumentEntityImpl(
      id: json['id'] as String,
      type: $enumDecode(_$DocumentTypeEnumMap, json['type']),
      url: json['url'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );

Map<String, dynamic> _$$DocumentEntityImplToJson(
        _$DocumentEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$DocumentTypeEnumMap[instance.type]!,
      'url': instance.url,
      'uploadedAt': instance.uploadedAt.toIso8601String(),
    };

const _$DocumentTypeEnumMap = {
  DocumentType.passport: 'PASSPORT',
  DocumentType.drivingLicense: 'DRIVING_LICENSE',
  DocumentType.diploma: 'DIPLOMA',
};
