import 'dart:io';
import '../entities/user_entity.dart';

abstract class IProfileRepository {
  Future<UserEntity> getProfile();
  Future<UserEntity> updateProfile(Map<String, dynamic> data);
  Future<DocumentEntity> uploadDocument({required File file, required DocumentType type});
  Future<void> deleteDocument(String documentId);
}
