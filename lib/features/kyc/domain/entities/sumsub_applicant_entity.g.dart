// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sumsub_applicant_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SumsubApplicantEntityImpl _$$SumsubApplicantEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$SumsubApplicantEntityImpl(
      applicantId: json['applicantId'] as String,
      createdAt: json['createdAt'] as String?,
      reviewStatus: json['reviewStatus'] as String?,
      reviewResult: json['reviewResult'] == null
          ? null
          : SumsubReviewResult.fromJson(
              json['reviewResult'] as Map<String, dynamic>),
      info: json['info'] == null
          ? null
          : SumsubPersonInfo.fromJson(json['info'] as Map<String, dynamic>),
      addresses: (json['addresses'] as List<dynamic>?)
              ?.map((e) => SumsubAddress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      idDocs: (json['idDocs'] as List<dynamic>?)
              ?.map((e) => SumsubIdDoc.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$SumsubApplicantEntityImplToJson(
        _$SumsubApplicantEntityImpl instance) =>
    <String, dynamic>{
      'applicantId': instance.applicantId,
      'createdAt': instance.createdAt,
      'reviewStatus': instance.reviewStatus,
      'reviewResult': instance.reviewResult,
      'info': instance.info,
      'addresses': instance.addresses,
      'idDocs': instance.idDocs,
    };

_$SumsubReviewResultImpl _$$SumsubReviewResultImplFromJson(
        Map<String, dynamic> json) =>
    _$SumsubReviewResultImpl(
      reviewAnswer: json['reviewAnswer'] as String?,
      rejectLabels: (json['rejectLabels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$SumsubReviewResultImplToJson(
        _$SumsubReviewResultImpl instance) =>
    <String, dynamic>{
      'reviewAnswer': instance.reviewAnswer,
      'rejectLabels': instance.rejectLabels,
    };

_$SumsubPersonInfoImpl _$$SumsubPersonInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$SumsubPersonInfoImpl(
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      middleName: json['middleName'] as String?,
      dob: json['dob'] as String?,
      placeOfBirth: json['placeOfBirth'] as String?,
      country: json['country'] as String?,
      nationality: json['nationality'] as String?,
      gender: json['gender'] as String?,
    );

Map<String, dynamic> _$$SumsubPersonInfoImplToJson(
        _$SumsubPersonInfoImpl instance) =>
    <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'middleName': instance.middleName,
      'dob': instance.dob,
      'placeOfBirth': instance.placeOfBirth,
      'country': instance.country,
      'nationality': instance.nationality,
      'gender': instance.gender,
    };

_$SumsubAddressImpl _$$SumsubAddressImplFromJson(Map<String, dynamic> json) =>
    _$SumsubAddressImpl(
      street: json['street'] as String?,
      buildingNumber: json['buildingNumber'] as String?,
      flatNumber: json['flatNumber'] as String?,
      town: json['town'] as String?,
      state: json['state'] as String?,
      postCode: json['postCode'] as String?,
      country: json['country'] as String?,
    );

Map<String, dynamic> _$$SumsubAddressImplToJson(_$SumsubAddressImpl instance) =>
    <String, dynamic>{
      'street': instance.street,
      'buildingNumber': instance.buildingNumber,
      'flatNumber': instance.flatNumber,
      'town': instance.town,
      'state': instance.state,
      'postCode': instance.postCode,
      'country': instance.country,
    };

_$SumsubIdDocImpl _$$SumsubIdDocImplFromJson(Map<String, dynamic> json) =>
    _$SumsubIdDocImpl(
      idDocType: json['idDocType'] as String?,
      number: json['number'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      issuedDate: json['issuedDate'] as String?,
      validUntil: json['validUntil'] as String?,
      issuedBy: json['issuedBy'] as String?,
      country: json['country'] as String?,
    );

Map<String, dynamic> _$$SumsubIdDocImplToJson(_$SumsubIdDocImpl instance) =>
    <String, dynamic>{
      'idDocType': instance.idDocType,
      'number': instance.number,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'issuedDate': instance.issuedDate,
      'validUntil': instance.validUntil,
      'issuedBy': instance.issuedBy,
      'country': instance.country,
    };
