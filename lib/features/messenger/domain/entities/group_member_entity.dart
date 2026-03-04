import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_member_entity.freezed.dart';
part 'group_member_entity.g.dart';

@freezed
class GroupMemberEntity with _$GroupMemberEntity {
  const factory GroupMemberEntity({
    required String id,
    required String userId,
    required String role,
    String? firstName,
    String? lastName,
    String? username,
    String? avatarUrl,
    DateTime? joinedAt,
  }) = _GroupMemberEntity;

  factory GroupMemberEntity.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberEntityFromJson(json);
}
