import '../entities/session_entity.dart';

abstract class ISessionRepository {
  Future<List<SessionEntity>> getSessions();
  Future<void> deleteSession(String sessionId);
}
