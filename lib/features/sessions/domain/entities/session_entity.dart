import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_entity.freezed.dart';
part 'session_entity.g.dart';

@freezed
class SessionEntity with _$SessionEntity {
  const factory SessionEntity({
    required String id,
    String? device,
    String? ip,
    String? location,
    required DateTime createdAt,
    DateTime? lastActiveAt,
    @Default(false) bool isCurrent,
  }) = _SessionEntity;

  factory SessionEntity.fromJson(Map<String, dynamic> json) =>
      _$SessionEntityFromJson(json);
}
