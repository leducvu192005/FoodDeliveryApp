import 'dart:io';

class ApiConfig {
  static const String _apiBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_apiBaseUrlFromEnv.isNotEmpty) {
      return _trimTrailingSlash(_apiBaseUrlFromEnv);
    }

    if (Platform.isAndroid) {
      // Android emulator -> host machine localhost
      return 'http://10.0.2.2:8000';
    }

    if (Platform.isIOS) {
      return 'http://localhost:8000';
    }

    return 'http://localhost:8000';
  }

  static String path(String endpoint) {
    final normalized = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$baseUrl$normalized';
  }

  // Backward-compatible endpoints for existing screens/services.
  static String get categoryUrl => path('/api/category/');
  static String get dishUrl => path('/api/dish/');
  static String get toppingUrl => path('/api/topping/');
  static String get profileUrl => path('/profile/');

  static String _trimTrailingSlash(String url) {
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }
}
