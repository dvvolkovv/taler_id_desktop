import '../../../../core/api/dio_client.dart';

class KycRemoteDataSource {
  final DioClient client;
  KycRemoteDataSource(this.client);

  Future<String> startKyc() async {
    final data = await client.post<Map<String, dynamic>>(
      '/kyc/start',
      data: {},
      fromJson: (d) => Map<String, dynamic>.from(d),
    );
    return data['sdkToken'] as String;
  }

  Future<Map<String, dynamic>> getKycStatus() =>
      client.get('/kyc/status', fromJson: (d) => Map<String, dynamic>.from(d));
}
