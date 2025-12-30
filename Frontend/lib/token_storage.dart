import 'dart:convert';
import 'package:http/http.dart' as http;

class Api {
  static const base = "http://10.0.2.2:8000";

  static Future login(String email, String pass) async {
    final res = await http.post(
      Uri.parse("$base/auth/login"),
      body: {"email": email, "password": pass},
    );
    return jsonDecode(res.body);
  }

  static Future register(String email, String pass, String role) async {
    await http.post(
      Uri.parse("$base/auth/register"),
      body: {"email": email, "password": pass, "role": role},
    );
  }
}
