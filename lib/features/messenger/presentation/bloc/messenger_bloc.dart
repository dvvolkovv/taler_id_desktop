import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/i_messenger_repository.dart';
import 'messenger_event.dart';
import 'messenger_state.dart';

class MessengerBloc extends Bloc<MessengerEvent, MessengerState> {
  final IMessengerRepository _repo;
  StreamSubscription? _msgSub;
  StreamSubscription? _callSub;
  StreamSubscription? _msgUpdatedSub;
  StreamSubscription? _msgsReadSub;

  MessengerBloc({required IMessengerRepository repo})
      : _repo = repo,
        super(const MessengerState()) {
    on<ConnectMessenger>(_onConnect);
    on<LoadConversations>(_onLoadConversations);
    on<OpenConversation>(_onOpenConversation);
    on<SendMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SearchUsers>(_onSearchUsers);
    on<StartConversationWith>(_onStartConversationWith);
    on<ClearNewConversation>((_, emit) =>
        emit(state.copyWith(clearNewConversation: true)));
    on<CallInviteReceived>(
        (event, emit) => emit(state.copyWith(pendingCallInvite: event.data)));
    on<DismissCallInvite>(
        (_, emit) => emit(state.copyWith(clearCallInvite: true)));
    on<MessageUpdated>(_onMessageUpdated);
    on<MessagesRead>(_onMessagesRead);
    on<MarkConversationRead>(_onMarkConversationRead);
  }

  Future<void> _onConnect(
      ConnectMessenger event, Emitter<MessengerState> emit) async {
    await _repo.connect(event.accessToken);
    _msgSub?.cancel();
    _msgSub = _repo.messageStream.listen((msg) => add(MessageReceived(msg)));
    _callSub?.cancel();
    _callSub = _repo.callInviteStream.listen((data) => add(CallInviteReceived(data)));
    _msgUpdatedSub?.cancel();
    _msgUpdatedSub = _repo.messageUpdatedStream.listen((data) {
      final id = data['id'] as String?;
      if (id != null) {
        add(MessageUpdated(id,
          isDelivered: data['isDelivered'] as bool?,
          isRead: data['isRead'] as bool?,
        ));
      }
    });
    _msgsReadSub?.cancel();
    _msgsReadSub = _repo.messagesReadStream.listen((data) {
      final convId = data['conversationId'] as String?;
      final ids = (data['messageIds'] as List?)?.cast<String>() ?? [];
      if (convId != null && ids.isNotEmpty) {
        add(MessagesRead(convId, ids));
      }
    });
    emit(state.copyWith(
      isConnected: true,
      currentUserId: event.userId ?? state.currentUserId,
    ));
    add(LoadConversations());
  }

  Future<void> _onLoadConversations(
      LoadConversations event, Emitter<MessengerState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final convs = await _repo.getConversations();
      // Sort: most recent message on top
      convs.sort((a, b) {
        final aTime = a.lastMessageAt;
        final bTime = b.lastMessageAt;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      emit(state.copyWith(conversations: convs, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onOpenConversation(
      OpenConversation event, Emitter<MessengerState> emit) async {
    _repo.joinConversation(event.conversationId);
    emit(state.copyWith(isLoading: true));
    try {
      final result = await _repo.getMessages(event.conversationId);
      final rawMessages = result['messages'] as List? ?? [];
      // Build a lookup of known read/delivered status to preserve checkmarks
      final knownStatus = <String, ({bool isRead, bool isDelivered})>{
        for (final m in state.messages[event.conversationId] ?? [])
          m.id: (isRead: m.isRead, isDelivered: m.isDelivered),
      };
      final msgs = rawMessages.map((e) {
        final m = MessageEntity.fromJson(Map<String, dynamic>.from(e as Map));
        final known = knownStatus[m.id];
        if (known != null) {
          return m.copyWith(
            isRead: m.isRead || known.isRead,
            isDelivered: m.isDelivered || known.isDelivered,
          );
        }
        return m;
      }).toList();
      final nextCursor = result['nextCursor'] as String?;
      final newMessages =
          Map<String, List<MessageEntity>>.from(state.messages);
      newMessages[event.conversationId] = msgs.reversed.toList();
      final newCursors = Map<String, String?>.from(state.nextCursors);
      newCursors[event.conversationId] = nextCursor;
      emit(state.copyWith(
          messages: newMessages, nextCursors: newCursors, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _onSendMessage(SendMessage event, Emitter<MessengerState> emit) {
    // Optimistic: show message in UI immediately
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = MessageEntity(
      id: tempId,
      conversationId: event.conversationId,
      senderId: state.currentUserId ?? 'me',
      content: event.content,
      sentAt: DateTime.now(),
      fileUrl: event.fileUrl,
      fileName: event.fileName,
      fileSize: event.fileSize,
      fileType: event.fileType,
    );
    final existing =
        List<MessageEntity>.from(state.messages[event.conversationId] ?? []);
    existing.add(tempMsg);
    final newMessages =
        Map<String, List<MessageEntity>>.from(state.messages);
    newMessages[event.conversationId] = existing;
    emit(state.copyWith(messages: newMessages));
    // Send via socket
    _repo.sendMessage(
      event.conversationId,
      event.content,
      fileUrl: event.fileUrl,
      fileName: event.fileName,
      fileSize: event.fileSize,
      fileType: event.fileType,
    );
  }

  void _onMessageReceived(
      MessageReceived event, Emitter<MessengerState> emit) {
    final msg = event.message;
    final existing =
        List<MessageEntity>.from(state.messages[msg.conversationId] ?? []);
    // Deduplicate: skip if already have this message ID (can arrive twice via room + personal rooms)
    if (existing.any((m) => m.id == msg.id)) return;
    // Remove optimistic temp message with same content from same sender
    existing.removeWhere((m) =>
        m.id.startsWith('temp_') &&
        m.senderId == msg.senderId &&
        m.content == msg.content);
    existing.add(msg);
    final newMessages =
        Map<String, List<MessageEntity>>.from(state.messages);
    newMessages[msg.conversationId] = existing;
    emit(state.copyWith(messages: newMessages));
    // Refresh conversations to update last message preview
    add(LoadConversations());
  }

  Future<void> _onLoadMoreMessages(
      LoadMoreMessages event, Emitter<MessengerState> emit) async {
    final cursor = state.nextCursors[event.conversationId];
    if (cursor == null) return;
    try {
      final result =
          await _repo.getMessages(event.conversationId, cursor: cursor);
      final rawMessages = result['messages'] as List? ?? [];
      final newMsgs = rawMessages
          .map((e) =>
              MessageEntity.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final nextCursor = result['nextCursor'] as String?;
      final existing = List<MessageEntity>.from(
          state.messages[event.conversationId] ?? []);
      final allMessages =
          Map<String, List<MessageEntity>>.from(state.messages);
      allMessages[event.conversationId] = [
        ...newMsgs.reversed.toList(),
        ...existing,
      ];
      final newCursors = Map<String, String?>.from(state.nextCursors);
      newCursors[event.conversationId] = nextCursor;
      emit(state.copyWith(messages: allMessages, nextCursors: newCursors));
    } catch (_) {}
  }

  Future<void> _onSearchUsers(
      SearchUsers event, Emitter<MessengerState> emit) async {
    if (event.query.length < 2) {
      emit(state.copyWith(searchResults: []));
      return;
    }
    emit(state.copyWith(isLoading: true));
    try {
      final results = await _repo.searchUsers(event.query);
      emit(state.copyWith(searchResults: results, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onStartConversationWith(
      StartConversationWith event, Emitter<MessengerState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final conv = await _repo.createConversation(event.userId);
      emit(state.copyWith(
          isLoading: false, newConversationId: conv.id));
      add(LoadConversations());
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _onMessageUpdated(MessageUpdated event, Emitter<MessengerState> emit) {
    final allMessages = Map<String, List<MessageEntity>>.from(state.messages);
    for (final convId in allMessages.keys) {
      final msgs = List<MessageEntity>.from(allMessages[convId]!);
      final idx = msgs.indexWhere((m) => m.id == event.messageId);
      if (idx != -1) {
        msgs[idx] = msgs[idx].copyWith(
          isDelivered: event.isDelivered ?? msgs[idx].isDelivered,
          isRead: event.isRead ?? msgs[idx].isRead,
        );
        allMessages[convId] = msgs;
        emit(state.copyWith(messages: allMessages));
        return;
      }
    }
  }

  void _onMessagesRead(MessagesRead event, Emitter<MessengerState> emit) {
    final msgs = List<MessageEntity>.from(state.messages[event.conversationId] ?? []);
    bool changed = false;
    for (int i = 0; i < msgs.length; i++) {
      if (event.messageIds.contains(msgs[i].id)) {
        msgs[i] = msgs[i].copyWith(isRead: true, isDelivered: true);
        changed = true;
      }
    }
    if (changed) {
      final allMessages = Map<String, List<MessageEntity>>.from(state.messages);
      allMessages[event.conversationId] = msgs;
      emit(state.copyWith(messages: allMessages));
    }
  }

  void _onMarkConversationRead(MarkConversationRead event, Emitter<MessengerState> emit) {
    _repo.markRead(event.conversationId);
    // Immediately clear unread badge in local state (don't wait for next API refresh)
    final updatedConvs = state.conversations.map((c) {
      if (c.id == event.conversationId) return c.copyWith(unreadCount: 0);
      return c;
    }).toList();
    emit(state.copyWith(conversations: updatedConvs));
  }

  @override
  Future<void> close() {
    _msgSub?.cancel();
    _callSub?.cancel();
    _msgUpdatedSub?.cancel();
    _msgsReadSub?.cancel();
    _repo.dispose();
    return super.close();
  }
}
