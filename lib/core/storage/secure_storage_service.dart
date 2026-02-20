import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.unlocked),
  );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: ApiConstants.accessTokenKey, value: accessToken),
      _storage.write(key: ApiConstants.refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: ApiConstants.accessTokenKey);

  Future<String?> getRefreshToken() =>
      _storage.read(key: ApiConstants.refreshTokenKey);

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: ApiConstants.accessTokenKey),
      _storage.delete(key: ApiConstants.refreshTokenKey),
    ]);
  }

  Future<bool> get isBiometricEnabled async {
    final val = await _storage.read(key: ApiConstants.biometricEnabledKey);
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: ApiConstants.biometricEnabledKey, value: enabled.toString());

  Future<String?> getUserId() =>
      _storage.read(key: ApiConstants.userIdKey);

  Future<void> saveUserId(String userId) =>
      _storage.write(key: ApiConstants.userIdKey, value: userId);

  Future<bool> get hasRefreshToken async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }
}
