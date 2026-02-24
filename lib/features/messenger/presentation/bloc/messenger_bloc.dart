import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/i_messenger_repository.dart';
import 'messenger_event.dart';
import 'messenger_state.dart';

class MessengerBloc extends Bloc<MessengerEvent, MessengerState> {
  final IMessengerRepository _repo;
  StreamSubscription? _msgSub;

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
  }

  Future<void> _onConnect(
      ConnectMessenger event, Emitter<MessengerState> emit) async {
    await _repo.connect(event.accessToken);
    _msgSub = _repo.messageStream.listen((msg) => add(MessageReceived(msg)));
    add(LoadConversations());
  }

  Future<void> _onLoadConversations(
      LoadConversations event, Emitter<MessengerState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final convs = await _repo.getConversations();
      emit(state.copyWith(conversations: convs, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onOpenConversation(
      OpenConversation event, Emitter<MessengerState> emit) async {
    _repo.joinConversation(event.conversationId);
    if (state.messages.containsKey(event.conversationId)) return;
    emit(state.copyWith(isLoading: true));
    try {
      final result = await _repo.getMessages(event.conversationId);
      final rawMessages = result['messages'] as List? ?? [];
      final msgs = rawMessages
          .map((e) =>
              MessageEntity.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
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
    _repo.sendMessage(event.conversationId, event.content);
  }

  void _onMessageReceived(
      MessageReceived event, Emitter<MessengerState> emit) {
    final msg = event.message;
    final existing =
        List<MessageEntity>.from(state.messages[msg.conversationId] ?? []);
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

  @override
  Future<void> close() {
    _msgSub?.cancel();
    _repo.dispose();
    return super.close();
  }
}
