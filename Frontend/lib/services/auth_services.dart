import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class AuthService {
  static String get baseUrl => ApiConfig.path('/auth');

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static Future<String?> register(
    String fullName,
    String email,
    String sdt,
    String password,
    String role, {
    String? cccd,
    String? vehicleRegistration,
    String? license,
    String? nameShop,
    String? addressShop,
  }) async {
    final body = {
      "full_name": fullName,
      "email": email,
      "sdt": sdt,
      "password": password,
      "role": role,
    };
    if (cccd != null && cccd.isNotEmpty) body["cccd"] = cccd;
    if (vehicleRegistration != null && vehicleRegistration.isNotEmpty)
      body["vehicle_registration"] = vehicleRegistration;
    if (license != null && license.isNotEmpty) body["license"] = license;
    if (nameShop != null && nameShop.isNotEmpty) body["name_shop"] = nameShop;
    if (addressShop != null && addressShop.isNotEmpty)
      body["address_shop"] = addressShop;

    final res = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) return null;
    try {
      final data = jsonDecode(res.body);
      return data['detail'] ?? 'Dang ky that bai';
    } catch (_) {
      return 'Dang ky that bai';
    }
  }

  static Future<Map<String, String?>?> login(
      String email, String sdt, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "sdt": sdt,
        "password": password,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      debugPrint("Nhan access token thanh cong");

      await _storage.write(
        key: "access_token",
        value: data["access_token"],
      );

      return {
        "role": data["role"]?.toString(),
        "status": data["status"]?.toString(),
      };
    }
    return null;
  }

  static Future<Map<String, dynamic>?> switchRole(String role) async {
    final token = await getToken();
    if (token == null) return null;
    final res = await http.post(
      Uri.parse("$baseUrl/switch-role"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"role": role}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await _storage.write(key: "access_token", value: data["access_token"]);
      return data;
    }
    final data = jsonDecode(res.body);
    return {"error": data["detail"] ?? "Khong the chuyen role"};
  }

  // Lay token da luu trong secure storage.
  static Future<String?> getToken() async {
    return _storage.read(key: "access_token");
  }

  static Future<void> logout() async {
    await _storage.delete(key: "access_token");
  }

  static Future<String?> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse("$baseUrl/forgot-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    if (res.statusCode == 200) return null;
    try {
      final data = jsonDecode(res.body);
      return data['detail'] ?? 'Gui OTP that bai';
    } catch (_) {
      return 'Gui OTP that bai';
    }
  }

  static Future<String?> resetPassword(
      String email, String otp, String newPassword) async {
    final res = await http.post(
      Uri.parse("$baseUrl/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "otp": otp,
        "new_password": newPassword,
      }),
    );
    if (res.statusCode == 200) return null;
    try {
      final data = jsonDecode(res.body);
      return data['detail'] ?? 'Dat lai mat khau that bai';
    } catch (_) {
      return 'Dat lai mat khau that bai';
    }
  }
}
