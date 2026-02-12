import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';

class CategoryService {
  static const String _baseUrl = 'http://10.0.2.2:8000';

  static Future<List<Category>> fetchCategories() async {
    final res = await http.get(Uri.parse('$_baseUrl/api/category'));

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Category.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }
}
