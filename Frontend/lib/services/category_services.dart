import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../config/api_config.dart';
import 'auth_services.dart';

class CategoryService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<List<Category>> fetchCategories() async {
    try {
      final token = await AuthService.getToken();

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // Thêm token nếu có (cho buyer đã đăng nhập)
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final res = await http.get(
        Uri.parse('$_baseUrl/api/category?view_all=true'),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => Category.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load categories: ${res.statusCode}');
      }
    } catch (e) {
      print('[CategoryService] error: $e');
      rethrow;
    }
  }
}
