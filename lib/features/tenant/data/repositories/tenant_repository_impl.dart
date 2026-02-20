import '../../domain/entities/tenant_entity.dart';
import '../../domain/repositories/i_tenant_repository.dart';
import '../datasources/tenant_remote_datasource.dart';
import '../../../../core/storage/cache_service.dart';

class TenantRepositoryImpl implements ITenantRepository {
  final TenantRemoteDataSource remote;
  final CacheService cache;

  TenantRepositoryImpl({required this.remote, required this.cache});

  @override
  Future<List<TenantEntity>> getMyTenants() async {
    try {
      final list = await remote.getMyTenants();
      await cache.saveTenants(list);
      return list.map(TenantEntity.fromJson).toList();
    } catch (_) {
      final cached = cache.getTenants();
      if (cached != null) return cached.map(TenantEntity.fromJson).toList();
      rethrow;
    }
  }

  @override
  Future<TenantEntity> getTenant(String tenantId) async {
    final data = await remote.getTenant(tenantId);
    return TenantEntity.fromJson(data);
  }

  @override
  Future<TenantEntity> createTenant(Map<String, dynamic> data) async {
    final result = await remote.createTenant(data);
    return TenantEntity.fromJson(result);
  }

  @override
  Future<TenantEntity> updateTenant(String tenantId, Map<String, dynamic> data) async {
    final result = await remote.updateTenant(tenantId, data);
    return TenantEntity.fromJson(result);
  }

  @override
  Future<void> inviteMember({required String tenantId, required String email, required TenantRole role}) =>
      remote.inviteMember(tenantId: tenantId, email: email, role: role.name.toUpperCase());

  @override
  Future<void> updateMember({required String tenantId, required String memberId, required TenantRole role}) =>
      remote.updateMember(tenantId: tenantId, memberId: memberId, role: role.name.toUpperCase());

  @override
  Future<void> acceptInvite(String token) => remote.acceptInvite(token);

  @override
  Future<void> removeMember({required String tenantId, required String userId}) =>
      remote.removeMember(tenantId: tenantId, userId: userId);

  @override
  Future<String> startKyb(String tenantId) => remote.startKyb(tenantId);

  @override
  Future<Map<String, dynamic>> getKybStatus(String tenantId) => remote.getKybStatus(tenantId);
}
