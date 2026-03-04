import 'package:equatable/equatable.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/user_search_entity.dart';
import '../../domain/entities/group_member_entity.dart';

class MessengerState extends Equatable {
  final List<ConversationEntity> conversations;
  final Map<String, List<MessageEntity>> messages;
  final Map<String, String?> nextCursors;
  final List<UserSearchEntity> searchResults;
  final bool isLoading;
  final bool isConnected;
  final String? error;
  final String? newConversationId;
  final String? currentUserId;
  final Map<String, dynamic>? pendingCallInvite;
  final Map<String, List<GroupMemberEntity>> groupMembers;

  const MessengerState({
    this.conversations = const [],
    this.messages = const {},
    this.nextCursors = const {},
    this.searchResults = const [],
    this.isLoading = false,
    this.isConnected = false,
    this.error,
    this.newConversationId,
    this.currentUserId,
    this.pendingCallInvite,
    this.groupMembers = const {},
  });

  MessengerState copyWith({
    List<ConversationEntity>? conversations,
    Map<String, List<MessageEntity>>? messages,
    Map<String, String?>? nextCursors,
    List<UserSearchEntity>? searchResults,
    bool? isLoading,
    bool? isConnected,
    String? error,
    String? newConversationId,
    String? currentUserId,
    Map<String, dynamic>? pendingCallInvite,
    Map<String, List<GroupMemberEntity>>? groupMembers,
    bool clearError = false,
    bool clearNewConversation = false,
    bool clearCallInvite = false,
  }) {
    return MessengerState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      nextCursors: nextCursors ?? this.nextCursors,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      error: clearError ? null : (error ?? this.error),
      newConversationId: clearNewConversation
          ? null
          : (newConversationId ?? this.newConversationId),
      currentUserId: currentUserId ?? this.currentUserId,
      pendingCallInvite:
          clearCallInvite ? null : (pendingCallInvite ?? this.pendingCallInvite),
      groupMembers: groupMembers ?? this.groupMembers,
    );
  }

  @override
  List<Object?> get props => [
        conversations,
        messages,
        nextCursors,
        searchResults,
        isLoading,
        isConnected,
        error,
        newConversationId,
        currentUserId,
        pendingCallInvite,
        groupMembers,
      ];
}
