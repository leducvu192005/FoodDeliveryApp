import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String baseUrl = "http://10.0.2.2:8000/auth";

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static Future<bool> register(
    String fullName,
    String email,
    String password,
    String role,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "full_name": fullName,
        "email": email,
        "password": password,
        "role": role,
      }),
    );

    return res.statusCode == 200;
  }

  static Future<String?> login(String email, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      print("TOKEN NHẬN ĐƯỢC: ${data["access_token"]}");

      await _storage.write(
        key: "access_token",
        value: data["access_token"],
      );

      return data["role"];
    }
    return null;
  }

// lấy token
  static Future<String?> getToken() async {
    return await _storage.read(key: "access_token");
  }

  static Future<void> logout() async {
    await _storage.delete(key: "access_token");
  }
}
