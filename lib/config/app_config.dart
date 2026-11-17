/// Global Application Configuration
/// Central place to set backend API Base URL and dynamic settings.
class AppConfig {
  /// =========================================================================
  /// LIVE PRODUCTION / HOSTED API BASE URL
  /// =========================================================================
  static String baseUrl = 'https://agsdemo.in/iplapi/public/api';

  /// Sanitized base URL with trailing slashes stripped
  static String get cleanBaseUrl {
    var url = baseUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static const String appName = 'IPL FPL Boys';
  static const String appVersion = '1.0.0';

  /// Default fallback Profile ID if not yet selected
  static const String defaultProfileId = 'ea5b7b03-d0b4-4a98-ab3a-4c6b1297794c';
  static const String defaultProfileName = 'AREA 51';

  /// Dynamic IPL Team Colors (Hex)
  static const Map<String, int> iplColors = {
    'csk': 0xFFF9CD05,
    'dc': 0xFF004C93,
    'gt': 0xFF1C2B4B,
    'kkr': 0xFF3A225D,
    'lsg': 0xFF0057E7,
    'mi': 0xFF004BA0,
    'pk': 0xFFED1B24,
    'pbks': 0xFFED1B24,
    'rcb': 0xFFEC1C24,
    'rr': 0xFFEA1A85,
    'srh': 0xFFF26522,
  };
}
