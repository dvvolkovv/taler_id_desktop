import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

class ProfileRemoteDataSource {
  final DioClient client;
  ProfileRemoteDataSource(this.client);

  Future<Map<String, dynamic>> getProfile() =>
      client.get('/profile', fromJson: (d) => Map<String, dynamic>.from(d));

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) =>
      client.put('/profile', data: data, fromJson: (d) => Map<String, dynamic>.from(d));

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
}
