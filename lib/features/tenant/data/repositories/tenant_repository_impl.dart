import 'dart:convert';
import '../../domain/entities/tenant_entity.dart';
import '../../domain/repositories/i_tenant_repository.dart';
import '../datasources/tenant_remote_datasource.dart';
import '../../../../core/storage/cache_service.dart';
import '../../../../core/storage/secure_storage_service.dart';

class TenantRepositoryImpl implements ITenantRepository {
  final TenantRemoteDataSource remote;
  final CacheService cache;
  final SecureStorageService storage;

  TenantRepositoryImpl({required this.remote, required this.cache, required this.storage});

  /// Maps backend Prisma tenant fields to entity field names.
  Map<String, dynamic> _mapTenant(Map<String, dynamic> json, {String? currentUserId}) {
    final mapped = Map<String, dynamic>.from(json);
    mapped['email'] = json['contactEmail'];
    mapped['phone'] = json['contactPhone'];
    mapped['address'] = json['legalAddress'];
    // getMyTenants returns 'role', getTenant does not
    if (json.containsKey('role') && !json.containsKey('myRole')) {
      mapped['myRole'] = json['role'];
    }
    // getTenant includes members with nested user object
    if (json['members'] is List) {
      mapped['members'] = (json['members'] as List).map((m) {
        final member = Map<String, dynamic>.from(m as Map);
        // Flatten user.email/firstName/lastName into member
        if (member['user'] is Map) {
          final user = member['user'] as Map;
          member['email'] = user['email'] ?? '';
          member['firstName'] = user['firstName'];
          member['lastName'] = user['lastName'];
          member['userId'] = user['id'];
          // Determine myRole from members list
          if (currentUserId != null && user['id'] == currentUserId) {
            mapped['myRole'] = member['role'];
          }
        }
        return member;
      }).toList();
    }
    return mapped;
  }

  @override
  Future<List<TenantEntity>> getMyTenants() async {
    try {
      final list = await remote.getMyTenants();
      await cache.saveTenants(list);
      return list.map((json) => TenantEntity.fromJson(_mapTenant(json))).toList();
    } catch (_) {
      final cached = cache.getTenants();
      if (cached != null) {
        return cached.map((json) => TenantEntity.fromJson(_mapTenant(json))).toList();
      }
      rethrow;
    }
  }

  Future<String?> _getCurrentUserId() async {
    var userId = await storage.getUserId();
    if (userId == null) {
      // Extract from stored access token
      try {
        final token = await storage.getAccessToken();
        if (token != null) {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
            final map = jsonDecode(payload) as Map<String, dynamic>;
            userId = map['sub'] as String?;
            if (userId != null) await storage.saveUserId(userId);
          }
        }
      } catch (_) {}
    }
    return userId;
  }

  @override
  Future<TenantEntity> getTenant(String tenantId) async {
    final data = await remote.getTenant(tenantId);
    final userId = await _getCurrentUserId();
    return TenantEntity.fromJson(_mapTenant(data, currentUserId: userId));
  }

  @override
  Future<void> createTenant(Map<String, dynamic> data) async {
    await remote.createTenant(data);
  }

  @override
  Future<void> updateTenant(String tenantId, Map<String, dynamic> data) async {
    await remote.updateTenant(tenantId, data);
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
