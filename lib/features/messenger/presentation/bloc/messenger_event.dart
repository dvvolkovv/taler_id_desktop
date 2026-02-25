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
