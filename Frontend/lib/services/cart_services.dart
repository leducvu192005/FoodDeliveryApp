import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_services.dart';
import '../config/api_config.dart';

class CartServices {
  static String get baseUrl => ApiConfig.path('/cart');

  // Header có token
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Chưa đăng nhập');
    }

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token', // 👈 QUAN TRỌNG
    };
  }

  // 1. Lấy danh sách món trong giỏ
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final url = Uri.parse('$baseUrl/items');

    final response = await http.get(
      url,
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      print('Lỗi: ${response.body}');
      return [];
    }
  }

  // 2. Thêm vào giỏ
  Future<bool> addToCart({
    required int dishId,
    int quantity = 1,
  }) async {
    final url = Uri.parse('$baseUrl/add');

    final response = await http.post(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({
        'dish_id': dishId,
        'quantity': quantity,
      }),
    );

    return response.statusCode == 200;
  }

  // 3. Cập nhật số lượng
  Future<bool> updateQuantity(int dishId, int quantity) async {
    final url = Uri.parse('$baseUrl/update');

    final response = await http.put(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({
        'dish_id': dishId,
        'quantity': quantity,
      }),
    );

    return response.statusCode == 200;
  }

  // 4. Xóa món
  Future<bool> removeFromCart(int dishId) async {
    final url = Uri.parse('$baseUrl/remove?dish_id=$dishId');

    final response = await http.delete(
      url,
      headers: await _authHeaders(),
    );

    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> checkout() async {
    final url = Uri.parse('$baseUrl/checkout');

    final response = await http.post(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({
        "method": "stripe",
      }),
    );
    if (response.statusCode != 200) {
      throw Exception("Checkout thất bại: ${response.body}");
    }
    return jsonDecode(response.body);
  }
}
