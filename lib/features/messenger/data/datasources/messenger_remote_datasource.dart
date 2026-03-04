import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/api/dio_client.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/user_search_entity.dart';

class MessengerRemoteDataSource {
  final DioClient _http;
  io.Socket? _socket;
  final _messageCtrl = StreamController<MessageEntity>.broadcast();
  final _callInviteCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _callEndedCtrl = StreamController<String>.broadcast();
  final _callAnsweredCtrl = StreamController<String>.broadcast();
  final _joinedConversations = <String>{};
  final _disconnectCtrl = StreamController<String>.broadcast();
  final _messageUpdatedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _messagesReadCtrl = StreamController<Map<String, dynamic>>.broadcast();

  MessengerRemoteDataSource(this._http);

  Future<void> connect(String accessToken) async {
    _socket?.dispose();
    _socket = io.io(
      'https://id.taler.tirol/messenger',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .disableAutoConnect()
          .build(),
    );
    _socket!.on('new_message', (d) {
      try {
        _messageCtrl.add(MessageEntity.fromJson(Map<String, dynamic>.from(d as Map)));
      } catch (_) {}
    });
    _socket!.on('call_invite', (d) {
      try {
        _callInviteCtrl.add(Map<String, dynamic>.from(d as Map));
      } catch (_) {}
    });
    _socket!.on('call_ended', (d) {
      try {
        final data = Map<String, dynamic>.from(d as Map);
        _callEndedCtrl.add(data['roomName'] as String? ?? '');
      } catch (_) {}
    });
    _socket!.on('message_updated', (d) {
      try {
        _messageUpdatedCtrl.add(Map<String, dynamic>.from(d as Map));
      } catch (_) {}
    });
    _socket!.on('messages_read', (d) {
      try {
        _messagesReadCtrl.add(Map<String, dynamic>.from(d as Map));
      } catch (_) {}
    });
    _socket!.on('call_answered', (d) {
      try {
        final data = Map<String, dynamic>.from(d as Map);
        _callAnsweredCtrl.add(data['roomName'] as String? ?? '');
      } catch (_) {}
    });
    // Re-join all conversation rooms after reconnect
    _socket!.on('connect', (_) {
      for (final id in _joinedConversations) {
        _socket?.emit('join', {'conversationId': id});
      }
    });
    _socket!.on('disconnect', (reason) {
      _disconnectCtrl.add(reason?.toString() ?? 'disconnected');
    });
    _socket!.connect();
  }

  Stream<MessageEntity> get messageStream => _messageCtrl.stream;
  Stream<Map<String, dynamic>> get callInviteStream => _callInviteCtrl.stream;
  Stream<String> get callEndedStream => _callEndedCtrl.stream;
  Stream<String> get callAnsweredStream => _callAnsweredCtrl.stream;
  Stream<String> get disconnectStream => _disconnectCtrl.stream;
  Stream<Map<String, dynamic>> get messageUpdatedStream => _messageUpdatedCtrl.stream;
  Stream<Map<String, dynamic>> get messagesReadStream => _messagesReadCtrl.stream;
  bool get isSocketConnected => _socket?.connected ?? false;

  void joinConversation(String id) {
    _joinedConversations.add(id);
    _socket?.emit('join', {'conversationId': id});
  }

  void sendMessage(
    String id,
    String content, {
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? fileType,
  }) {
    final payload = <String, dynamic>{'conversationId': id, 'content': content};
    if (fileUrl != null) {
      payload['fileUrl'] = fileUrl;
      payload['fileName'] = fileName;
      payload['fileSize'] = fileSize;
      payload['fileType'] = fileType;
    }
    _socket?.emit('message', payload);
  }

  void sendTyping(String id, bool isTyping) =>
      _socket?.emit('typing', {'conversationId': id, 'isTyping': isTyping});

  void sendCallInvite(String conversationId, String roomName, {String? inviteeId, String? e2eeKey}) =>
      _socket?.emit('call_invite', {
        'conversationId': conversationId,
        'roomName': roomName,
        if (inviteeId != null) 'inviteeId': inviteeId,
        if (e2eeKey != null) 'e2eeKey': e2eeKey,
      });

  void sendCallEnded(String conversationId, String roomName) =>
      _socket?.emit('call_ended', {'conversationId': conversationId, 'roomName': roomName});

  void sendCallAnswered(String conversationId, String roomName) =>
      _socket?.emit('call_answered', {'conversationId': conversationId, 'roomName': roomName});

  void markRead(String conversationId) =>
      _socket?.emit('mark_read', {'conversationId': conversationId});

  Future<List<ConversationEntity>> getConversations() async {
    final data = await _http.get('/messenger/conversations', fromJson: (d) => d as List);
    return data
        .map((e) => ConversationEntity.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ConversationEntity> createConversation(String participantId) async {
    final data = await _http.post(
      '/messenger/conversations',
      data: {'participantId': participantId},
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
    return ConversationEntity.fromJson(data);
  }

  Future<Map<String, dynamic>> getMessages(String conversationId, {String? cursor}) async {
    final url = cursor != null
        ? '/messenger/conversations/$conversationId/messages?cursor=$cursor'
        : '/messenger/conversations/$conversationId/messages';
    return _http.get(url, fromJson: (d) => Map<String, dynamic>.from(d as Map));
  }

  Future<List<UserSearchEntity>> searchUsers(String query) async {
    final data = await _http.get(
      '/messenger/users/search?q=${Uri.encodeComponent(query)}',
      fromJson: (d) => d as List,
    );
    return data
        .map((e) => UserSearchEntity.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  void dispose() {
    _socket?.dispose();
    _messageCtrl.close();
    _callInviteCtrl.close();
    _callEndedCtrl.close();
    _disconnectCtrl.close();
    _messageUpdatedCtrl.close();
    _messagesReadCtrl.close();
  }
}
