import 'package:equatable/equatable.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/user_search_entity.dart';

class MessengerState extends Equatable {
  final List<ConversationEntity> conversations;
  final Map<String, List<MessageEntity>> messages;
  final Map<String, String?> nextCursors;
  final List<UserSearchEntity> searchResults;
  final bool isLoading;
  final String? error;
  final String? newConversationId;
  final String? currentUserId;

  const MessengerState({
    this.conversations = const [],
    this.messages = const {},
    this.nextCursors = const {},
    this.searchResults = const [],
    this.isLoading = false,
    this.error,
    this.newConversationId,
    this.currentUserId,
  });

  MessengerState copyWith({
    List<ConversationEntity>? conversations,
    Map<String, List<MessageEntity>>? messages,
    Map<String, String?>? nextCursors,
    List<UserSearchEntity>? searchResults,
    bool? isLoading,
    String? error,
    String? newConversationId,
    String? currentUserId,
    bool clearError = false,
    bool clearNewConversation = false,
  }) {
    return MessengerState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      nextCursors: nextCursors ?? this.nextCursors,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      newConversationId: clearNewConversation
          ? null
          : (newConversationId ?? this.newConversationId),
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }

  @override
  List<Object?> get props => [
        conversations,
        messages,
        nextCursors,
        searchResults,
        isLoading,
        error,
        newConversationId,
        currentUserId,
      ];
}
