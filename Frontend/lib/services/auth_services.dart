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
  try {
    print("📤 === BẮT ĐẦU ĐĂNG KÝ ===");
    print("📤 URL: $baseUrl/register");
    print("📤 Full name: $fullName");
    print("📤 Email: $email");
    print("📤 Password length: ${password.length}");
    print("📤 Role: $role");
    
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

    print("📥 Response Status: ${res.statusCode}");
    print("📥 Response Body: ${res.body}");

    if (res.statusCode == 200) {
      print("✅ ĐĂNG KÝ THÀNH CÔNG");
      return true;
    } else {
      print("❌ ĐĂNG KÝ THẤT BẠI - Status: ${res.statusCode}");
      return false;
    }
  } catch (e) {
    print("❌ LỖI EXCEPTION: $e");
    return false;
  }
}

  // 🔥 LOGIN + LƯU TOKEN
  static Future<String?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      print("Login Status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // ✅ LƯU ACCESS TOKEN
        await _storage.write(key: "access_token", value: data["access_token"]);

        return data["role"];
      }
    } catch (e) {
      print("Lỗi login: $e");
    }
    return null;
  }

  // (Tuỳ chọn) logout
  static Future<void> logout() async {
    await _storage.delete(key: "access_token");
  }
}
