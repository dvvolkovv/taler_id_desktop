import 'dart:convert';
import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../../core/storage/secure_storage_service.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDataSource remote;
  final SecureStorageService storage;

  AuthRepositoryImpl({required this.remote, required this.storage});

  Future<void> _saveUserIdFromToken(String accessToken) async {
    try {
      final parts = accessToken.split('.');
      if (parts.length == 3) {
        final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        final map = jsonDecode(payload) as Map<String, dynamic>;
        final sub = map['sub'] as String?;
        if (sub != null) await storage.saveUserId(sub);
      }
    } catch (_) {}
  }

  @override
  Future<AuthTokens> login({required String email, required String password}) async {
    final data = await remote.login(email, password);
    if (data['requires2FA'] == true) {
      // Signal 2FA needed by throwing with special data
      throw TwoFARequiredException(
        tempToken: data['tempToken'] as String,
        email: email,
      );
    }
    final tokens = AuthTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    await storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    await _saveUserIdFromToken(tokens.accessToken);
    return tokens;
  }

  @override
  Future<AuthTokens> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    final data = await remote.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
    final tokens = AuthTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    await storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    await _saveUserIdFromToken(tokens.accessToken);
    return tokens;
  }

  @override
  Future<AuthTokens> verify2FA({
    required String email,
    required String code,
    required String tempToken,
  }) async {
    final data = await remote.verify2FA(
      email: email,
      code: code,
      tempToken: tempToken,
    );
    final tokens = AuthTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    await storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    await _saveUserIdFromToken(tokens.accessToken);
    return tokens;
  }

  @override
  Future<AuthTokens> refreshToken(String refreshToken) async {
    // Handled by AuthInterceptor
    throw UnimplementedError('Handled by AuthInterceptor');
  }

  @override
  Future<void> logout() async {
    try {
      await remote.logout();
    } catch (_) {
      // Server call may fail (expired token, network error) — ignore
    }
    await storage.clearTokens();
  }
}

class TwoFARequiredException implements Exception {
  final String tempToken;
  final String email;
  TwoFARequiredException({required this.tempToken, required this.email});
}
