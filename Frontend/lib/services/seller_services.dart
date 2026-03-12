import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_services.dart';

class SellerService {
  static String get _baseUrl => ApiConfig.path('/seller');

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Chua dang nhap');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  /// Lấy profile seller
  Future<Map<String, dynamic>> getProfile() async {
    final url = Uri.parse('$_baseUrl/profile');
    final resp = await http.get(url, headers: await _authHeaders());
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    throw Exception(
        'Khong lay duoc thong tin quan (${resp.statusCode}: ${resp.body})');
  }

  /// Cập nhật profile seller
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/profile');
    final resp = await http.put(
      url,
      headers: await _authHeaders(),
      body: jsonEncode(data),
    );
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    throw Exception('Cap nhat that bai');
  }

  /// Lấy trạng thái quán (on/off)
  Future<Map<String, dynamic>> getStatus() async {
    final url = Uri.parse('$_baseUrl/status');
    final resp = await http.get(url, headers: await _authHeaders());
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    throw Exception(
        'Khong lay duoc trang thai quan (${resp.statusCode}: ${resp.body})');
  }

  /// Bật / tắt quán
  Future<Map<String, dynamic>> toggleStatus(String status) async {
    final url = Uri.parse('$_baseUrl/status');
    final resp = await http.patch(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({'status': status}),
    );
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    throw Exception('Khong cap nhat duoc trang thai');
  }

  /// Doanh thu
  Future<Map<String, dynamic>> getRevenue() async {
    final url = Uri.parse('$_baseUrl/revenue');
    final resp = await http.get(url, headers: await _authHeaders());
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    throw Exception(
        'Khong lay duoc doanh thu (${resp.statusCode}: ${resp.body})');
  }

  /// Seller đánh dấu đã làm xong đơn
  Future<Map<String, dynamic>> markOrderDone(int orderId) async {
    final url = Uri.parse('$_baseUrl/orders/$orderId/done');
    final resp = await http.patch(url, headers: await _authHeaders());
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    throw Exception('Khong cap nhat duoc don hang');
  }
}
