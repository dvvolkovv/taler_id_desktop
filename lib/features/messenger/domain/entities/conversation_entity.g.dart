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
      type: json['type'] as String? ?? 'DIRECT',
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
      myRole: json['myRole'] as String?,
      lastMessageContent: json['lastMessageContent'] as String?,
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      lastMessageSenderName: json['lastMessageSenderName'] as String?,
      lastMessageIsSystem: json['lastMessageIsSystem'] as bool? ?? false,
      otherUserName: json['otherUserName'] as String?,
      otherUserId: json['otherUserId'] as String?,
      otherUserAvatar: json['otherUserAvatar'] as String?,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ConversationEntityImplToJson(
        _$ConversationEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'participantIds': instance.participantIds,
      'type': instance.type,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
      'participantCount': instance.participantCount,
      'myRole': instance.myRole,
      'lastMessageContent': instance.lastMessageContent,
      'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
      'lastMessageSenderId': instance.lastMessageSenderId,
      'lastMessageSenderName': instance.lastMessageSenderName,
      'lastMessageIsSystem': instance.lastMessageIsSystem,
      'otherUserName': instance.otherUserName,
      'otherUserId': instance.otherUserId,
      'otherUserAvatar': instance.otherUserAvatar,
      'unreadCount': instance.unreadCount,
    };
