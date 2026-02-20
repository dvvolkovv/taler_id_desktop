import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';
part 'user_entity.g.dart';

enum KycStatus {
  @JsonValue('UNVERIFIED') unverified,
  @JsonValue('PENDING') pending,
  @JsonValue('VERIFIED') verified,
  @JsonValue('REJECTED') rejected,
}

@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String email,
    String? phone,
    String? firstName,
    String? lastName,
    String? country,
    String? avatarUrl,
    String? postalCode,
    String? dateOfBirth,
    @Default(KycStatus.unverified) KycStatus kycStatus,
    String? fcmToken,
    List<DocumentEntity>? documents,
  }) = _UserEntity;

  factory UserEntity.fromJson(Map<String, dynamic> json) =>
      _$UserEntityFromJson(json);
}

enum DocumentType {
  @JsonValue('PASSPORT') passport,
  @JsonValue('DRIVING_LICENSE') drivingLicense,
  @JsonValue('DIPLOMA') diploma,
}

@freezed
class DocumentEntity with _$DocumentEntity {
  const factory DocumentEntity({
    required String id,
    required DocumentType type,
    required String url,
    required DateTime uploadedAt,
  }) = _DocumentEntity;

  factory DocumentEntity.fromJson(Map<String, dynamic> json) =>
      _$DocumentEntityFromJson(json);
}
