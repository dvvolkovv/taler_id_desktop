import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_search_entity.freezed.dart';
part 'user_search_entity.g.dart';

@freezed
class UserSearchEntity with _$UserSearchEntity {
  const factory UserSearchEntity({
    required String id,
    String? username,
    String? firstName,
    String? lastName,
    required String email,
    String? avatarUrl,
  }) = _UserSearchEntity;

  factory UserSearchEntity.fromJson(Map<String, dynamic> json) =>
      _$UserSearchEntityFromJson(json);
}
