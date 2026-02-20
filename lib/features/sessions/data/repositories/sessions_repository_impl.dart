import '../../domain/entities/session_entity.dart';
import '../../domain/repositories/i_session_repository.dart';
import '../datasources/sessions_remote_datasource.dart';

class SessionsRepositoryImpl implements ISessionRepository {
  final SessionsRemoteDataSource remote;
  SessionsRepositoryImpl(this.remote);

  @override
  Future<List<SessionEntity>> getSessions() async {
    final list = await remote.getSessions();
    return list.map(SessionEntity.fromJson).toList();
  }

  @override
  Future<void> deleteSession(String sessionId) =>
      remote.deleteSession(sessionId);
}
