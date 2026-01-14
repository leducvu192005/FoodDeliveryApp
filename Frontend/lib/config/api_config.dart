import 'dart:io';

class ApiConfig {
  // Base URL cho API
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Android Emulator sử dụng 10.0.2.2 để truy cập localhost của máy host
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      // iOS Simulator có thể dùng localhost
      return 'http://localhost:8000';
    } else {
      // Web hoặc desktop
      return 'http://localhost:8000';
    }
  }

  // API endpoints
  static String get categoryUrl => '$baseUrl/api/category/';
  static String get dishUrl => '$baseUrl/api/dish/';
  static String get toppingUrl => '$baseUrl/api/topping/';
    static String get profileUrl => '$baseUrl/profile/'; 
}
