import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

class ProfileRemoteDataSource {
  final DioClient client;
  ProfileRemoteDataSource(this.client);

  Future<Map<String, dynamic>> getProfile() =>
      client.get('/profile', fromJson: (d) => Map<String, dynamic>.from(d));

  Future<Map<String, dynamic>> uploadDocument({
    required File file,
    required String type,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      'type': type,
    });
    return client.postForm('/profile/documents', formData: formData,
        fromJson: (d) => Map<String, dynamic>.from(d));
  }

  Future<void> deleteDocument(String documentId) =>
      client.delete('/profile/documents/$documentId');

  Future<void> updatePhone(String phone) =>
      client.put('/profile/phone', data: {'phone': phone}, fromJson: (d) => d);

  Future<Map<String, dynamic>> exportData() =>
      client.get('/profile/export', fromJson: (d) => Map<String, dynamic>.from(d));

  Future<void> deleteAccount() => client.delete('/profile');
}
