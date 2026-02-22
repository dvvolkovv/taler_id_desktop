import 'package:freezed_annotation/freezed_annotation.dart';

part 'sumsub_applicant_entity.freezed.dart';
part 'sumsub_applicant_entity.g.dart';

@freezed
class SumsubApplicantEntity with _$SumsubApplicantEntity {
  const factory SumsubApplicantEntity({
    required String applicantId,
    String? createdAt,
    String? reviewStatus,
    SumsubReviewResult? reviewResult,
    SumsubPersonInfo? info,
    @Default([]) List<SumsubAddress> addresses,
    @Default([]) List<SumsubIdDoc> idDocs,
  }) = _SumsubApplicantEntity;

  factory SumsubApplicantEntity.fromJson(Map<String, dynamic> json) =>
      _$SumsubApplicantEntityFromJson(json);
}

@freezed
class SumsubReviewResult with _$SumsubReviewResult {
  const factory SumsubReviewResult({
    String? reviewAnswer,
    @Default([]) List<String> rejectLabels,
  }) = _SumsubReviewResult;

  factory SumsubReviewResult.fromJson(Map<String, dynamic> json) =>
      _$SumsubReviewResultFromJson(json);
}

@freezed
class SumsubPersonInfo with _$SumsubPersonInfo {
  const factory SumsubPersonInfo({
    String? firstName,
    String? lastName,
    String? middleName,
    String? dob,
    String? placeOfBirth,
    String? country,
    String? nationality,
    String? gender,
  }) = _SumsubPersonInfo;

  factory SumsubPersonInfo.fromJson(Map<String, dynamic> json) =>
      _$SumsubPersonInfoFromJson(json);
}

@freezed
class SumsubAddress with _$SumsubAddress {
  const factory SumsubAddress({
    String? street,
    String? buildingNumber,
    String? flatNumber,
    String? town,
    String? state,
    String? postCode,
    String? country,
  }) = _SumsubAddress;

  factory SumsubAddress.fromJson(Map<String, dynamic> json) =>
      _$SumsubAddressFromJson(json);
}

@freezed
class SumsubIdDoc with _$SumsubIdDoc {
  const factory SumsubIdDoc({
    String? idDocType,
    String? number,
    String? firstName,
    String? lastName,
    String? issuedDate,
    String? validUntil,
    String? issuedBy,
    String? country,
  }) = _SumsubIdDoc;

  factory SumsubIdDoc.fromJson(Map<String, dynamic> json) =>
      _$SumsubIdDocFromJson(json);
}
