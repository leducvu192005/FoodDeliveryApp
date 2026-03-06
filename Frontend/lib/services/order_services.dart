import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_services.dart';

class OrderServices {
  static String get _baseUrl => ApiConfig.path('/cart');

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Chua dang nhap');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    final url = Uri.parse('$_baseUrl/orders');
    final response = await http.get(url, headers: await _authHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception('Khong tai duoc don hang: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getSellerOrders() async {
    final url = Uri.parse('$_baseUrl/seller-orders');
    final response = await http.get(url, headers: await _authHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception('Khong tai duoc don hang: ${response.statusCode}');
  }
}
