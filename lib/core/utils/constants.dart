class ApiConstants {
  static const baseUrl = 'https://id.taler.tirol';
  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';
  static const biometricEnabledKey = 'biometric_enabled';
  static const userIdKey = 'user_id';
  static const pinHashKey = 'pin_hash';
  static const pinEnabledKey = 'pin_enabled';
  static const languageKey = 'app_language';
}

class RouteConstants {
  static const splash = '/splash';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const twoFA = '/auth/2fa';
  static const dashboard = '/dashboard';
  static const profile = '/dashboard/profile';

  static const kyc = '/dashboard/kyc';
  static const kycSumsub = '/dashboard/kyc/sumsub';
  static const organization = '/dashboard/organization';
  static const organizationDetail = '/dashboard/organization/:id';
  static const organizationMembers = '/dashboard/organization/:id/members';
  static const sessions = '/dashboard/sessions';
  static const settings = '/dashboard/settings';
  static const invite = '/invite';
  static const pinSetup = '/auth/pin-setup';
  static const pinEntry = '/auth/pin-entry';
  static const chat = '/chat';
  static const assistant = '/dashboard/assistant';
  static const messenger = '/dashboard/messenger';
  static const messengerSearch = '/dashboard/messenger/search';
  static const voice = '/dashboard/voice';
}
