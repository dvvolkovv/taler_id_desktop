import 'package:equatable/equatable.dart';
import '../../domain/entities/message_entity.dart';

abstract class MessengerEvent extends Equatable {
  const MessengerEvent();
  @override
  List<Object?> get props => [];
}

class ConnectMessenger extends MessengerEvent {
  final String accessToken;
  final String? userId;
  const ConnectMessenger(this.accessToken, {this.userId});
  @override
  List<Object?> get props => [accessToken, userId];
}

class ClearNewConversation extends MessengerEvent {}

class LoadConversations extends MessengerEvent {}

class OpenConversation extends MessengerEvent {
  final String conversationId;
  const OpenConversation(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class SendMessage extends MessengerEvent {
  final String conversationId;
  final String content;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileType;
  const SendMessage(
    this.conversationId,
    this.content, {
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileType,
  });
  @override
  List<Object?> get props => [conversationId, content, fileUrl, fileName];
}

class MessageReceived extends MessengerEvent {
  final MessageEntity message;
  const MessageReceived(this.message);
  @override
  List<Object?> get props => [message];
}

class LoadMoreMessages extends MessengerEvent {
  final String conversationId;
  const LoadMoreMessages(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class SearchUsers extends MessengerEvent {
  final String query;
  const SearchUsers(this.query);
  @override
  List<Object?> get props => [query];
}

class StartConversationWith extends MessengerEvent {
  final String userId;
  const StartConversationWith(this.userId);
  @override
  List<Object?> get props => [userId];
}

class CallInviteReceived extends MessengerEvent {
  final Map<String, dynamic> data;
  const CallInviteReceived(this.data);
  @override
  List<Object?> get props => [data];
}

class DismissCallInvite extends MessengerEvent {}

class MessageUpdated extends MessengerEvent {
  final String messageId;
  final bool? isDelivered;
  final bool? isRead;
  final String? content;
  final bool? isEdited;
  const MessageUpdated(this.messageId, {this.isDelivered, this.isRead, this.content, this.isEdited});
  @override
  List<Object?> get props => [messageId, isDelivered, isRead, content, isEdited];
}

class EditMessage extends MessengerEvent {
  final String conversationId;
  final String messageId;
  final String newContent;
  const EditMessage({required this.conversationId, required this.messageId, required this.newContent});
  @override
  List<Object?> get props => [conversationId, messageId, newContent];
}

class MessagesRead extends MessengerEvent {
  final String conversationId;
  final List<String> messageIds;
  const MessagesRead(this.conversationId, this.messageIds);
  @override
  List<Object?> get props => [conversationId, messageIds];
}

class MarkConversationRead extends MessengerEvent {
  final String conversationId;
  const MarkConversationRead(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

// ─── Group events ───

class CreateGroup extends MessengerEvent {
  final String name;
  final List<String> participantIds;
  const CreateGroup({required this.name, required this.participantIds});
  @override
  List<Object?> get props => [name, participantIds];
}

class LoadGroupMembers extends MessengerEvent {
  final String conversationId;
  const LoadGroupMembers(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class AddGroupMembers extends MessengerEvent {
  final String conversationId;
  final List<String> userIds;
  const AddGroupMembers({required this.conversationId, required this.userIds});
  @override
  List<Object?> get props => [conversationId, userIds];
}

class RemoveGroupMember extends MessengerEvent {
  final String conversationId;
  final String userId;
  const RemoveGroupMember({required this.conversationId, required this.userId});
  @override
  List<Object?> get props => [conversationId, userId];
}

class ChangeGroupRole extends MessengerEvent {
  final String conversationId;
  final String userId;
  final String role;
  const ChangeGroupRole({required this.conversationId, required this.userId, required this.role});
  @override
  List<Object?> get props => [conversationId, userId, role];
}

class UpdateGroupInfo extends MessengerEvent {
  final String conversationId;
  final String? name;
  final String? avatarUrl;
  const UpdateGroupInfo({required this.conversationId, this.name, this.avatarUrl});
  @override
  List<Object?> get props => [conversationId, name, avatarUrl];
}

class LeaveGroup extends MessengerEvent {
  final String conversationId;
  const LeaveGroup(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class DeleteGroup extends MessengerEvent {
  final String conversationId;
  const DeleteGroup(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class ForwardMessage extends MessengerEvent {
  final MessageEntity message;
  final String targetConversationId;
  const ForwardMessage({required this.message, required this.targetConversationId});
  @override
  List<Object?> get props => [message.id, targetConversationId];
}

// ─── Mute events ───

class MuteConversation extends MessengerEvent {
  final String conversationId;
  final int? durationMinutes;
  const MuteConversation({required this.conversationId, this.durationMinutes});
  @override
  List<Object?> get props => [conversationId, durationMinutes];
}

class UnmuteConversation extends MessengerEvent {
  final String conversationId;
  const UnmuteConversation(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

// ─── Group call events ───

class GroupCallStarted extends MessengerEvent {
  final String conversationId;
  final String roomName;
  const GroupCallStarted({required this.conversationId, required this.roomName});
  @override
  List<Object?> get props => [conversationId, roomName];
}

class GroupCallEnded extends MessengerEvent {
  final String conversationId;
  const GroupCallEnded(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class GroupEventReceived extends MessengerEvent {
  final String eventType;
  final Map<String, dynamic> data;
  const GroupEventReceived(this.eventType, this.data);
  @override
  List<Object?> get props => [eventType, data];
}
