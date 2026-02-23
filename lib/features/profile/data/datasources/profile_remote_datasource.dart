import '../../../../core/api/dio_client.dart';

class ProfileRemoteDataSource {
  final DioClient client;
  ProfileRemoteDataSource(this.client);

  Future<Map<String, dynamic>> getProfile() =>
      client.get('/profile', fromJson: (d) => Map<String, dynamic>.from(d));

  Future<void> updatePhone(String phone) =>
      client.put('/profile/phone', data: {'phone': phone}, fromJson: (d) => d);

  Future<Map<String, dynamic>> exportData() =>
      client.get('/profile/export', fromJson: (d) => Map<String, dynamic>.from(d));

  Future<void> deleteAccount() => client.delete('/profile');
}
