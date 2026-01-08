import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "http://10.0.2.2:8000/auth";

  static Future<bool> register(
    String fullName,
    String email,
    String password,
    String role,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "full_name": email.split("@")[0],
          "email": email,
          "password": password,
          "role": role,
        }),
      );

      return res.statusCode == 200;
    } catch (e) {
      print("Lỗi register: $e");
      return false;
    }
  }

  static Future<String?> login(String email, String password) async {
    try {
      final res = await http.post(
        // Lúc này nó sẽ ghép thành: .../auth/login (Chuẩn)
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      // Thêm log để dễ debug
      print("Login Status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data["role"];
      }
    } catch (e) {
      print("Lỗi login: $e");
    }
    return null;
  }
}
