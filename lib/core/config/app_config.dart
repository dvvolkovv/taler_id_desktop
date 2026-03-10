class AppConfig {
  static const String flavor =
      String.fromEnvironment('FLAVOR', defaultValue: 'prod');

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://id.taler.tirol',
  );

  static bool get isDev => flavor == 'dev';
  static bool get isProd => flavor == 'prod';
}
