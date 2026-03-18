import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';

/// On mobile: uses FlutterSecureStorage (encrypted keychain/keystore).
/// On web & desktop: uses Hive (localStorage-backed) since
/// FlutterSecureStorage can hang on macOS Keychain in sandboxed apps.
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.unlocked),
  );

  static const _hiveBoxName = 'auth_tokens';

  /// True when we should use Hive instead of FlutterSecureStorage.
  static bool get _useHive =>
      kIsWeb || (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux));

  static Future<void> initHive() async {
    if (_useHive) {
      await Hive.openBox(_hiveBoxName);
    }
  }

  /// Legacy alias so callers that call initWeb() still work.
  static Future<void> initWeb() => initHive();

  Box? get _hiveBox => _useHive ? Hive.box(_hiveBoxName) : null;

  // ---------------------------------------------------------------------------
  // Tokens
  // ---------------------------------------------------------------------------

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (_useHive) {
      final box = _hiveBox!;
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
    if (_useHive) {
      return _hiveBox?.get(ApiConstants.accessTokenKey) as String?;
    }
    try {
      return await _storage.read(key: ApiConstants.accessTokenKey);
    } catch (_) {
      try { await _storage.deleteAll(); } catch (_) {}
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    if (_useHive) {
      return _hiveBox?.get(ApiConstants.refreshTokenKey) as String?;
    }
    try {
      return await _storage.read(key: ApiConstants.refreshTokenKey);
    } catch (_) {
      try { await _storage.deleteAll(); } catch (_) {}
      return null;
    }
  }

  Future<void> clearTokens() async {
    if (_useHive) {
      final box = _hiveBox!;
      await box.delete(ApiConstants.accessTokenKey);
      await box.delete(ApiConstants.refreshTokenKey);
    } else {
      await Future.wait([
        _storage.delete(key: ApiConstants.accessTokenKey),
        _storage.delete(key: ApiConstants.refreshTokenKey),
      ]);
    }
  }

  // ---------------------------------------------------------------------------
  // Biometric
  // ---------------------------------------------------------------------------

  Future<bool> get isBiometricEnabled async {
    if (_useHive) {
      return _hiveBox?.get(ApiConstants.biometricEnabledKey) == 'true';
    }
    final val = await _storage.read(key: ApiConstants.biometricEnabledKey);
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    if (_useHive) {
      await _hiveBox?.put(ApiConstants.biometricEnabledKey, enabled.toString());
    } else {
      await _storage.write(key: ApiConstants.biometricEnabledKey, value: enabled.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // User ID
  // ---------------------------------------------------------------------------

  Future<String?> getUserId() async {
    if (_useHive) {
      return _hiveBox?.get(ApiConstants.userIdKey) as String?;
    }
    return _storage.read(key: ApiConstants.userIdKey);
  }

  Future<void> saveUserId(String userId) async {
    if (_useHive) {
      await _hiveBox?.put(ApiConstants.userIdKey, userId);
    } else {
      await _storage.write(key: ApiConstants.userIdKey, value: userId);
    }
  }

  Future<bool> get hasRefreshToken async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // PIN
  // ---------------------------------------------------------------------------

  Future<bool> get isPinEnabled async {
    if (_useHive) {
      return _hiveBox?.get(ApiConstants.pinEnabledKey) == 'true';
    }
    final val = await _storage.read(key: ApiConstants.pinEnabledKey);
    return val == 'true';
  }

  Future<void> setPinEnabled(bool enabled) async {
    if (_useHive) {
      await _hiveBox?.put(ApiConstants.pinEnabledKey, enabled.toString());
    } else {
      await _storage.write(key: ApiConstants.pinEnabledKey, value: enabled.toString());
    }
  }

  Future<String?> getPinHash() async {
    if (_useHive) {
      return _hiveBox?.get(ApiConstants.pinHashKey) as String?;
    }
    return _storage.read(key: ApiConstants.pinHashKey);
  }

  Future<void> savePinHash(String hash) async {
    if (_useHive) {
      await _hiveBox?.put(ApiConstants.pinHashKey, hash);
    } else {
      await _storage.write(key: ApiConstants.pinHashKey, value: hash);
    }
  }

  Future<void> clearPin() async {
    if (_useHive) {
      await _hiveBox?.delete(ApiConstants.pinHashKey);
      await _hiveBox?.delete(ApiConstants.pinEnabledKey);
    } else {
      await Future.wait([
        _storage.delete(key: ApiConstants.pinHashKey),
        _storage.delete(key: ApiConstants.pinEnabledKey),
      ]);
    }
  }

  // ---------------------------------------------------------------------------
  // Language
  // ---------------------------------------------------------------------------

  Future<String?> getLanguage() async {
    if (_useHive) {
      return _hiveBox?.get(ApiConstants.languageKey) as String?;
    }
    return _storage.read(key: ApiConstants.languageKey);
  }

  Future<void> saveLanguage(String lang) async {
    if (_useHive) {
      await _hiveBox?.put(ApiConstants.languageKey, lang);
    } else {
      await _storage.write(key: ApiConstants.languageKey, value: lang);
    }
  }

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------

  Future<String?> getThemeMode() async {
    if (_useHive) {
      return _hiveBox?.get(ApiConstants.themeKey) as String?;
    }
    return _storage.read(key: ApiConstants.themeKey);
  }

  Future<void> saveThemeMode(String mode) async {
    if (_useHive) {
      await _hiveBox?.put(ApiConstants.themeKey, mode);
    } else {
      await _storage.write(key: ApiConstants.themeKey, value: mode);
    }
  }

  // ---------------------------------------------------------------------------
  // Onboarding
  // ---------------------------------------------------------------------------

  Future<bool> get isOnboardingSeen async {
    if (_useHive) {
      return _hiveBox?.get(ApiConstants.onboardingSeenKey) == 'true';
    }
    final val = await _storage.read(key: ApiConstants.onboardingSeenKey);
    return val == 'true';
  }

  Future<void> setOnboardingSeen() async {
    if (_useHive) {
      await _hiveBox?.put(ApiConstants.onboardingSeenKey, 'true');
    } else {
      await _storage.write(key: ApiConstants.onboardingSeenKey, value: 'true');
    }
  }
}
