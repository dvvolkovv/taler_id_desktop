import 'package:equatable/equatable.dart';
import '../../domain/entities/session_entity.dart';

abstract class SessionsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SessionsInitial extends SessionsState {}
class SessionsLoading extends SessionsState {}

class SessionsLoaded extends SessionsState {
  final List<SessionEntity> sessions;
  SessionsLoaded(this.sessions);
  @override
  List<Object?> get props => [sessions];
}

class SessionsError extends SessionsState {
  final String message;
  SessionsError(this.message);
  @override
  List<Object?> get props => [message];
}
