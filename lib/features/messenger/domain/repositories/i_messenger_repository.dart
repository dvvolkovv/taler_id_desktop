import '../entities/conversation_entity.dart';
import '../entities/message_entity.dart';
import '../entities/user_search_entity.dart';

abstract class IMessengerRepository {
  Future<void> connect(String accessToken);
  Future<List<ConversationEntity>> getConversations();
  Future<ConversationEntity> createConversation(String participantId);
  Future<Map<String, dynamic>> getMessages(String conversationId, {String? cursor});
  Future<List<UserSearchEntity>> searchUsers(String query);
  void joinConversation(String id);
  void sendMessage(String conversationId, String content, {String? fileUrl, String? fileName, int? fileSize, String? fileType});
  void sendTyping(String conversationId, bool isTyping);
  void sendCallInvite(String conversationId, String roomName);
  Stream<MessageEntity> get messageStream;
  Stream<Map<String, dynamic>> get callInviteStream;
  void dispose();
}
