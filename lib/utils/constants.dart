class AppConstants {
  static const String appVersion = 'v0.0.2';
  static const String appName = 'Distribuciones GP';
  static const String defaultLanguage = 'es';
  static const String apiBaseUrl = 'https://api.gameplanet.com/epod5';
  static const String apiTimeout = '30'; // segundos
  //-- lo tomamos del .env
  static const String jwtMaster = String.fromEnvironment('JWT_TOKEN');
}
