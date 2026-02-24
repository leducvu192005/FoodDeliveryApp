import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dish.dart';
import '../config/api_config.dart';

class DishService {
  static String get _baseUrl => ApiConfig.baseUrl;

  /// Lấy tất cả món ăn (PUBLIC – không cần token)
  static Future<List<Product>> fetchDishes() async {
    final url = Uri.parse('$_baseUrl/api/dish');

    try {
      final res = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

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

  /// Lấy món ăn theo category (PUBLIC)
  static Future<List<Product>> fetchDishesByCategory(int categoryId) async {
    final url = Uri.parse('$_baseUrl/api/dish?category_id=$categoryId');

    final res = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('HTTP ${res.statusCode}');
    }
  }
}
