import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_services.dart';

class FavoriteService {
  static String get baseUrl => ApiConfig.path('/favorites');

  static Future<Map<String, String>?> _authHeaders() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Set<int>> getFavoriteIds() async {
    final headers = await _authHeaders();
    if (headers == null) {
      return <int>{};
    }

    final response = await http.get(Uri.parse(baseUrl), headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Khong tai duoc danh sach yeu thich: ${response.body}');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => item as Map<String, dynamic>)
        .map((item) => item['dish_id'] as int)
        .toSet();
  }

  Future<void> addFavorite(int dishId) async {
    final headers = await _authHeaders();
    if (headers == null) {
      throw Exception('Chua dang nhap');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/$dishId'),
      headers: headers,
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Khong them duoc yeu thich: ${response.body}');
    }
  }

  Future<void> removeFavorite(int dishId) async {
    final headers = await _authHeaders();
    if (headers == null) {
      throw Exception('Chua dang nhap');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/$dishId'),
      headers: headers,
    );

    if (response.statusCode != 204 && response.statusCode != 404) {
      throw Exception('Khong xoa duoc yeu thich: ${response.body}');
    }
  }
}
