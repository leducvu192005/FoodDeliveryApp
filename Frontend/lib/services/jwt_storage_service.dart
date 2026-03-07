import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class JwtStorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'shipper_jwt';

  static Future<void> saveToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() {
    return _storage.read(key: _tokenKey);
  }

  static Future<void> clear() {
    return _storage.delete(key: _tokenKey);
  }
}
