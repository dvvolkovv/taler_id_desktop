abstract class ChatEvent {}

class ChatMessageSent extends ChatEvent {
  final String text;
  ChatMessageSent(this.text);
}

class ChatStreamTokenReceived extends ChatEvent {
  final String token;
  ChatStreamTokenReceived(this.token);
}

class ChatStreamCompleted extends ChatEvent {}

class ChatStreamError extends ChatEvent {
  final String error;
  ChatStreamError(this.error);
}

class ChatCleared extends ChatEvent {}
