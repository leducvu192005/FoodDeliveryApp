import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_services.dart';

class AdminServices {
  static String get baseUrl => ApiConfig.path('/admin');

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Chua dang nhap');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> getStats() async {
    final url = Uri.parse('$baseUrl/stats');
    debugPrint('[AdminServices] GET $url');
    final response = await http.get(url, headers: await _authHeaders());
    debugPrint('[AdminServices] stats response: ${response.statusCode}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Khong lay duoc thong ke: ${response.body}');
  }

  static Future<List<Map<String, dynamic>>> getUsers() async {
    final url = Uri.parse('$baseUrl/users');
    final response = await http.get(url, headers: await _authHeaders());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Khong lay duoc danh sach user: ${response.body}');
  }

  static Future<Map<String, dynamic>> toggleUserActive(int userId) async {
    final url = Uri.parse('$baseUrl/users/$userId/toggle-active');
    final response = await http.patch(url, headers: await _authHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Thao tac that bai: ${response.body}');
  }

  static Future<List<Map<String, dynamic>>> getOrders() async {
    final url = Uri.parse('$baseUrl/orders');
    final response = await http.get(url, headers: await _authHeaders());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Khong lay duoc danh sach don hang: ${response.body}');
  }

  static Future<Map<String, dynamic>> changeUserRole(
      int userId, String newRole) async {
    final url = Uri.parse('$baseUrl/users/$userId/change-role');
    final response = await http.patch(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({'role': newRole}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Doi role that bai: ${response.body}');
  }

  static Future<List<Map<String, dynamic>>> getSellerForms() async {
    final url = Uri.parse('$baseUrl/seller-forms');
    final response = await http.get(url, headers: await _authHeaders());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Khong lay duoc danh sach ho so: ${response.body}');
  }

  static Future<Map<String, dynamic>> reviewSellerForm(
      int formId, String status) async {
    final url = Uri.parse('$baseUrl/seller-forms/$formId/review');
    final response = await http.patch(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Duyet ho so that bai: ${response.body}');
  }

  static Future<List<Map<String, dynamic>>> getShipperForms() async {
    final url = Uri.parse('$baseUrl/shipper-forms');
    final response = await http.get(url, headers: await _authHeaders());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Khong lay duoc danh sach ho so shipper: ${response.body}');
  }

  static Future<Map<String, dynamic>> reviewShipperForm(
      int formId, String status) async {
    final url = Uri.parse('$baseUrl/shipper-forms/$formId/review');
    final response = await http.patch(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Duyet ho so shipper that bai: ${response.body}');
  }

  static Future<List<Map<String, dynamic>>> getPendingUsers(String type) async {
    final url = Uri.parse('$baseUrl/pending-users?type=$type');
    final response = await http.get(url, headers: await _authHeaders());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Khong lay duoc danh sach cho duyet: ${response.body}');
  }

  static Future<Map<String, dynamic>> reviewPendingUser(
      int userId, String status) async {
    final url = Uri.parse('$baseUrl/pending-users/$userId/review');
    final response = await http.patch(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Duyet ho so that bai: ${response.body}');
  }
}
