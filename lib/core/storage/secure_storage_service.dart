import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';

/// On mobile: uses FlutterSecureStorage (encrypted keychain/keystore).
/// On web: uses Hive (localStorage-backed) since flutter_secure_storage's
/// SubtleCrypto encryption can hang during read operations.
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.unlocked),
  );

  static const _webBoxName = 'auth_tokens';

  static Future<void> initWeb() async {
    if (kIsWeb) {
      await Hive.openBox(_webBoxName);
    }
  }

  Box? get _webBox => kIsWeb ? Hive.box(_webBoxName) : null;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (kIsWeb) {
      final box = _webBox!;
      await box.put(ApiConstants.accessTokenKey, accessToken);
      await box.put(ApiConstants.refreshTokenKey, refreshToken);
    } else {
      await Future.wait([
        _storage.write(key: ApiConstants.accessTokenKey, value: accessToken),
        _storage.write(key: ApiConstants.refreshTokenKey, value: refreshToken),
      ]);
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      return _webBox?.get(ApiConstants.accessTokenKey) as String?;
    }
    return _storage.read(key: ApiConstants.accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      return _webBox?.get(ApiConstants.refreshTokenKey) as String?;
    }
    return _storage.read(key: ApiConstants.refreshTokenKey);
  }

  Future<void> clearTokens() async {
    if (kIsWeb) {
      final box = _webBox!;
      await box.delete(ApiConstants.accessTokenKey);
      await box.delete(ApiConstants.refreshTokenKey);
    } else {
      await Future.wait([
        _storage.delete(key: ApiConstants.accessTokenKey),
        _storage.delete(key: ApiConstants.refreshTokenKey),
      ]);
    }
  }

  Future<bool> get isBiometricEnabled async {
    if (kIsWeb) return false;
    final val = await _storage.read(key: ApiConstants.biometricEnabledKey);
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    if (kIsWeb) return;
    await _storage.write(key: ApiConstants.biometricEnabledKey, value: enabled.toString());
  }

  Future<String?> getUserId() async {
    if (kIsWeb) {
      return _webBox?.get(ApiConstants.userIdKey) as String?;
    }
    return _storage.read(key: ApiConstants.userIdKey);
  }

  Future<void> saveUserId(String userId) async {
    if (kIsWeb) {
      await _webBox?.put(ApiConstants.userIdKey, userId);
    } else {
      await _storage.write(key: ApiConstants.userIdKey, value: userId);
    }
  }

  Future<bool> get hasRefreshToken async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }
}
