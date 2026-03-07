import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _overrideBaseUrlKey = 'api_base_url_override';
  static const String _apiBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _apiBaseUrlAndroidDeviceFromEnv = String.fromEnvironment(
    'API_BASE_URL_ANDROID_DEVICE',
    defaultValue: '',
  );
  static String? _runtimeBaseUrlOverride;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_overrideBaseUrlKey)?.trim() ?? '';
    if (saved.isNotEmpty) {
      _runtimeBaseUrlOverride = _normalizeRawBaseUrl(saved);
    }
  }

  static String? get baseUrlOverride => _runtimeBaseUrlOverride;

  static Future<void> setBaseUrlOverride(String? rawUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = rawUrl?.trim() ?? '';

    if (trimmed.isEmpty) {
      _runtimeBaseUrlOverride = null;
      await prefs.remove(_overrideBaseUrlKey);
      return;
    }

    final normalized = _normalizeRawBaseUrl(trimmed);
    _runtimeBaseUrlOverride = normalized;
    await prefs.setString(_overrideBaseUrlKey, normalized);
  }

  static String get baseUrl {
    if (_runtimeBaseUrlOverride != null && _runtimeBaseUrlOverride!.isNotEmpty) {
      return _runtimeBaseUrlOverride!;
    }

    if (_apiBaseUrlFromEnv.isNotEmpty) {
      return _trimTrailingSlash(_apiBaseUrlFromEnv);
    }

    if (Platform.isAndroid) {
      // Real Android device should use LAN URL via --dart-define:
      // --dart-define=API_BASE_URL_ANDROID_DEVICE=http://192.168.x.x:8000
      if (_apiBaseUrlAndroidDeviceFromEnv.isNotEmpty) {
        return _trimTrailingSlash(_apiBaseUrlAndroidDeviceFromEnv);
      }

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

  static String _normalizeRawBaseUrl(String url) {
    final withScheme = RegExp(r'^https?://', caseSensitive: false).hasMatch(url)
        ? url
        : 'http://$url';
    return _trimTrailingSlash(withScheme);
  }
}
