import '../entities/tenant_entity.dart';

abstract class ITenantRepository {
  Future<List<TenantEntity>> getMyTenants();
  Future<TenantEntity> getTenant(String tenantId);
  Future<TenantEntity> createTenant(Map<String, dynamic> data);
  Future<TenantEntity> updateTenant(String tenantId, Map<String, dynamic> data);
  Future<void> inviteMember({required String tenantId, required String email, required TenantRole role});
  Future<void> updateMember({required String tenantId, required String memberId, required TenantRole role});
  Future<void> acceptInvite(String token);
  Future<void> removeMember({required String tenantId, required String userId});
  Future<String> startKyb(String tenantId);
  Future<Map<String, dynamic>> getKybStatus(String tenantId);
}
