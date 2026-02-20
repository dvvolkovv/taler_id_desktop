import 'package:freezed_annotation/freezed_annotation.dart';

part 'tenant_entity.freezed.dart';
part 'tenant_entity.g.dart';

enum KybStatus {
  @JsonValue('NONE') none,
  @JsonValue('PENDING') pending,
  @JsonValue('VERIFIED') verified,
  @JsonValue('REJECTED') rejected,
}

enum TenantRole {
  @JsonValue('OWNER') owner,
  @JsonValue('ADMIN') admin,
  @JsonValue('OPERATOR') operator,
  @JsonValue('VIEWER') viewer,
}

@freezed
class TenantEntity with _$TenantEntity {
  const factory TenantEntity({
    required String id,
    required String name,
    String? description,
    String? logoUrl,
    String? website,
    String? email,
    String? phone,
    String? address,
    @Default(KybStatus.none) KybStatus kybStatus,
    TenantRole? myRole,
    @Default([]) List<TenantMemberEntity> members,
  }) = _TenantEntity;

  factory TenantEntity.fromJson(Map<String, dynamic> json) =>
      _$TenantEntityFromJson(json);
}

@freezed
class TenantMemberEntity with _$TenantMemberEntity {
  const factory TenantMemberEntity({
    required String id,
    required String email,
    String? firstName,
    String? lastName,
    required TenantRole role,
    String? userId,
  }) = _TenantMemberEntity;

  factory TenantMemberEntity.fromJson(Map<String, dynamic> json) =>
      _$TenantMemberEntityFromJson(json);
}
