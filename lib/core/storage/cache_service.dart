import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const _profileBox = 'profile_cache';
  static const _kycBox = 'kyc_cache';
  static const _tenantBox = 'tenant_cache';
  static const _sumsubBox = 'sumsub_cache';

  static const _kycTtlSeconds = 300; // 5 minutes
  static const _sumsubTtlSeconds = 600; // 10 minutes

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(_profileBox),
      Hive.openBox(_kycBox),
      Hive.openBox(_tenantBox),
      Hive.openBox(_sumsubBox),
    ]);
  }

  // Profile cache
  Future<void> saveProfile(Map<String, dynamic> data) async {
    final box = Hive.box(_profileBox);
    await box.put('data', data);
    await box.put('timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Map<String, dynamic>? getProfile() {
    final box = Hive.box(_profileBox);
    final raw = box.get('data');
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<void> clearProfile() => Hive.box(_profileBox).clear();

  // KYC cache (5 min TTL)
  Future<void> saveKycStatus(Map<String, dynamic> data) async {
    final box = Hive.box(_kycBox);
    await box.put('data', data);
    await box.put('timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Map<String, dynamic>? getKycStatus() {
    final box = Hive.box(_kycBox);
    final timestamp = box.get('timestamp') as int?;
    if (timestamp == null) return null;
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (age > _kycTtlSeconds * 1000) return null; // expired
    return box.get('data') as Map<String, dynamic>?;
  }

  // Sumsub applicant data cache (10 min TTL)
  Future<void> saveSumsubData(Map<String, dynamic> data) async {
    final box = Hive.box(_sumsubBox);
    await box.put('data', data);
    await box.put('timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Map<String, dynamic>? getSumsubData() {
    final box = Hive.box(_sumsubBox);
    final timestamp = box.get('timestamp') as int?;
    if (timestamp == null) return null;
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (age > _sumsubTtlSeconds * 1000) return null; // expired
    return box.get('data') as Map<String, dynamic>?;
  }

  // Tenant cache
  Future<void> saveTenants(List<Map<String, dynamic>> data) async {
    final box = Hive.box(_tenantBox);
    await box.put('list', data);
    await box.put('timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  List<Map<String, dynamic>>? getTenants() {
    final box = Hive.box(_tenantBox);
    final raw = box.get('list');
    if (raw == null) return null;
    return List<Map<String, dynamic>>.from(raw as List);
  }

  Future<void> clearAll() async {
    await Future.wait([
      Hive.box(_profileBox).clear(),
      Hive.box(_kycBox).clear(),
      Hive.box(_tenantBox).clear(),
      Hive.box(_sumsubBox).clear(),
    ]);
  }
}
