// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConversationEntityImpl _$$ConversationEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$ConversationEntityImpl(
      id: json['id'] as String,
      participantIds: (json['participantIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      lastMessageContent: json['lastMessageContent'] as String?,
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      otherUserName: json['otherUserName'] as String?,
      otherUserId: json['otherUserId'] as String?,
      otherUserAvatar: json['otherUserAvatar'] as String?,
    );

Map<String, dynamic> _$$ConversationEntityImplToJson(
        _$ConversationEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'participantIds': instance.participantIds,
      'lastMessageContent': instance.lastMessageContent,
      'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
      'lastMessageSenderId': instance.lastMessageSenderId,
      'otherUserName': instance.otherUserName,
      'otherUserId': instance.otherUserId,
      'otherUserAvatar': instance.otherUserAvatar,
    };
