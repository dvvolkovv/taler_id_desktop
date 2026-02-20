import '../../../../core/api/dio_client.dart';

class SessionsRemoteDataSource {
  final DioClient client;
  SessionsRemoteDataSource(this.client);

  Future<List<Map<String, dynamic>>> getSessions() async {
    final data = await client.get<dynamic>('/auth/sessions', fromJson: (d) => d);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> deleteSession(String sessionId) =>
      client.delete('/auth/sessions/$sessionId');
}
