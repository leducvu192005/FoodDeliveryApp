import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dish.dart';
import '../config/api_config.dart';
import 'auth_services.dart';

class DishService {
  static String get _baseUrl => ApiConfig.baseUrl;

  /// Lấy tất cả món ăn
  static Future<List<Product>> fetchDishes() async {
    final url = Uri.parse('$_baseUrl/api/dish');

    try {
      final token = await AuthService.getToken();

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // Thêm token nếu có (cho buyer đã đăng nhập)
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final res = await http.get(url, headers: headers);

      print('[DishService] status: ${res.statusCode}');
      print('[DishService] body: ${res.body}');

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => Product.fromJson(e)).toList();
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      print('[DishService] error: $e');
      rethrow;
    }
  }

  /// Lấy món ăn theo category
  static Future<List<Product>> fetchDishesByCategory(int categoryId) async {
    final url = Uri.parse('$_baseUrl/api/dish?category_id=$categoryId');

    try {
      final token = await AuthService.getToken();

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final res = await http.get(url, headers: headers);

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => Product.fromJson(e)).toList();
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      print('[DishService] fetchDishesByCategory error: $e');
      rethrow;
    }
  }
}
