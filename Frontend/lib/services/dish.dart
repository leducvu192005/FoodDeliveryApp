import "dart:convert";
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductService {
  static Future<List> fetchProducts() async {
    final res = await http.get(Uri.parse('http://10.0.2.2:8000/api/dish'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }
}
