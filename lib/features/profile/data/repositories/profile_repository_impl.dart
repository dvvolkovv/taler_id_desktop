import 'dart:io';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../../../../core/storage/cache_service.dart';

class ProfileRepositoryImpl implements IProfileRepository {
  final ProfileRemoteDataSource remote;
  final CacheService cache;

  ProfileRepositoryImpl({required this.remote, required this.cache});

  @override
  Future<UserEntity> getProfile() async {
    try {
      final data = await remote.getProfile();
      await cache.saveProfile(data);
      return UserEntity.fromJson(data);
    } catch (_) {
      final cached = cache.getProfile();
      if (cached != null) return UserEntity.fromJson(cached);
      rethrow;
    }
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    await remote.updateProfile(data);
  }

  @override
  Future<DocumentEntity> uploadDocument({
    required File file,
    required DocumentType type,
  }) async {
    final typeName = type.name.toUpperCase();
    final data = await remote.uploadDocument(file: file, type: typeName);
    return DocumentEntity.fromJson(data);
  }

  @override
  Future<void> deleteDocument(String documentId) =>
      remote.deleteDocument(documentId);
}
