import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/i_chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final IChatRepository repo;
  StreamSubscription<String>? _streamSub;

  ChatBloc({required this.repo}) : super(const ChatState()) {
    on<ChatMessageSent>(_onMessageSent);
    on<ChatStreamTokenReceived>(_onTokenReceived);
    on<ChatStreamCompleted>(_onStreamCompleted);
    on<ChatStreamError>(_onStreamError);
    on<ChatCleared>(_onCleared);
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    // Cancel any active stream
    await _streamSub?.cancel();

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: event.text,
      timestamp: DateTime.now(),
    );

    final assistantMsg = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_ai',
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    emit(state.copyWith(
      messages: [...state.messages, userMsg, assistantMsg],
      isStreaming: true,
      error: null,
    ));

    try {
      final stream = repo.sendMessage(event.text);
      _streamSub = stream.listen(
        (token) => add(ChatStreamTokenReceived(token)),
        onDone: () => add(ChatStreamCompleted()),
        onError: (e) => add(ChatStreamError(e.toString())),
      );
    } catch (e) {
      add(ChatStreamError(e.toString()));
    }
  }

  void _onTokenReceived(
    ChatStreamTokenReceived event,
    Emitter<ChatState> emit,
  ) {
    if (state.messages.isEmpty) return;

    final messages = List<ChatMessage>.from(state.messages);
    final last = messages.last;
    messages[messages.length - 1] = last.copyWith(
      content: last.content + event.token,
    );

    emit(state.copyWith(messages: messages));
  }

  void _onStreamCompleted(
    ChatStreamCompleted event,
    Emitter<ChatState> emit,
  ) {
    if (state.messages.isEmpty) return;

    final messages = List<ChatMessage>.from(state.messages);
    final last = messages.last;
    messages[messages.length - 1] = last.copyWith(isStreaming: false);

    emit(state.copyWith(messages: messages, isStreaming: false));
  }

  void _onStreamError(
    ChatStreamError event,
    Emitter<ChatState> emit,
  ) {
    if (state.messages.isNotEmpty) {
      final messages = List<ChatMessage>.from(state.messages);
      final last = messages.last;
      if (last.role == MessageRole.assistant && last.content.isEmpty) {
        // Remove empty assistant message on error
        messages.removeLast();
      } else {
        messages[messages.length - 1] = last.copyWith(isStreaming: false);
      }
      emit(state.copyWith(
        messages: messages,
        isStreaming: false,
        error: event.error,
      ));
    } else {
      emit(state.copyWith(isStreaming: false, error: event.error));
    }
  }

  void _onCleared(ChatCleared event, Emitter<ChatState> emit) {
    _streamSub?.cancel();
    emit(const ChatState());
  }

  @override
  Future<void> close() {
    _streamSub?.cancel();
    return super.close();
  }
}
