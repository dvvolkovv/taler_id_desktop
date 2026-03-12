import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_entity.freezed.dart';
part 'message_entity.g.dart';

@freezed
class MessageEntity with _$MessageEntity {
  const factory MessageEntity({
    required String id,
    required String conversationId,
    required String senderId,
    String? senderName,
    required String content,
    required DateTime sentAt,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? fileType,
    @Default(false) bool isDelivered,
    @Default(false) bool isRead,
    @Default(false) bool isSystem,
    @Default(false) bool isEdited,
  }) = _MessageEntity;

  factory MessageEntity.fromJson(Map<String, dynamic> json) =>
      _$MessageEntityFromJson(json);
}
