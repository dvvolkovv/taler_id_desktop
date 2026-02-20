abstract class IKycRepository {
  Future<String> startKyc();
  Future<Map<String, dynamic>> getKycStatus();
}
