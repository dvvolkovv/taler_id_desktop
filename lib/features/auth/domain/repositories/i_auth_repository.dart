import '../entities/auth_entities.dart';

abstract class IAuthRepository {
  Future<AuthTokens> login({required String email, required String password});
  Future<AuthTokens> register({required String email, required String password, String? firstName, String? lastName, String? username});
  Future<AuthTokens> verify2FA({required String email, required String code, required String tempToken});
  Future<AuthTokens> refreshToken(String refreshToken);
  Future<void> logout();
}
