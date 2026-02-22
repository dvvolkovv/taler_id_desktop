import '../../domain/entities/chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isStreaming;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error,
    );
  }
}
