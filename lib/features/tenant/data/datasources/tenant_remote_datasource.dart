import '../../../../core/api/dio_client.dart';

class TenantRemoteDataSource {
  final DioClient client;
  TenantRemoteDataSource(this.client);

  Future<List<Map<String, dynamic>>> getMyTenants() async {
    final data = await client.get<dynamic>('/tenant', fromJson: (d) => d);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<Map<String, dynamic>> getTenant(String id) =>
      client.get('/tenant/$id', fromJson: (d) => Map<String, dynamic>.from(d));

  Future<Map<String, dynamic>> createTenant(Map<String, dynamic> data) =>
      client.post('/tenant', data: data, fromJson: (d) => Map<String, dynamic>.from(d));

  Future<Map<String, dynamic>> updateTenant(String id, Map<String, dynamic> data) =>
      client.put('/tenant/$id', data: data, fromJson: (d) => Map<String, dynamic>.from(d));

  Future<void> inviteMember({required String tenantId, required String email, required String role}) =>
      client.post('/tenant/$tenantId/members/invite', data: {'email': email, 'role': role});

  Future<void> updateMember({required String tenantId, required String memberId, required String role}) =>
      client.put('/tenant/$tenantId/members/$memberId/role', data: {'role': role});

  Future<void> acceptInvite(String token) =>
      client.post('/tenant/invites/$token/accept', data: {});
}
