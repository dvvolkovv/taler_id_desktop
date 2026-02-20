import 'package:equatable/equatable.dart';

abstract class SessionsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SessionsLoadRequested extends SessionsEvent {}

class SessionDeleteRequested extends SessionsEvent {
  final String sessionId;
  SessionDeleteRequested(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}
