import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/user_search_entity.dart';
import '../../domain/repositories/i_messenger_repository.dart';
import '../datasources/messenger_remote_datasource.dart';

class MessengerRepositoryImpl implements IMessengerRepository {
  final MessengerRemoteDataSource _remote;

  MessengerRepositoryImpl(this._remote);

  @override
  Future<void> connect(String accessToken) => _remote.connect(accessToken);

  @override
  Future<List<ConversationEntity>> getConversations() => _remote.getConversations();

  @override
  Future<ConversationEntity> createConversation(String participantId) =>
      _remote.createConversation(participantId);

  @override
  Future<Map<String, dynamic>> getMessages(String conversationId, {String? cursor}) =>
      _remote.getMessages(conversationId, cursor: cursor);

  @override
  Future<List<UserSearchEntity>> searchUsers(String query) => _remote.searchUsers(query);

  @override
  void joinConversation(String id) => _remote.joinConversation(id);

  @override
  void sendMessage(String conversationId, String content) =>
      _remote.sendMessage(conversationId, content);

  @override
  void sendTyping(String conversationId, bool isTyping) =>
      _remote.sendTyping(conversationId, isTyping);

  @override
  void sendCallInvite(String conversationId, String roomName) =>
      _remote.sendCallInvite(conversationId, roomName);

  @override
  Stream<MessageEntity> get messageStream => _remote.messageStream;

  @override
  Stream<Map<String, dynamic>> get callInviteStream => _remote.callInviteStream;

  @override
  void dispose() => _remote.dispose();
}
