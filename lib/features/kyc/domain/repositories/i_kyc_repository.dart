import '../entities/sumsub_applicant_entity.dart';

abstract class IKycRepository {
  Future<String> startKyc();
  Future<Map<String, dynamic>> getKycStatus();
  Future<SumsubApplicantEntity> getApplicantData();
}
