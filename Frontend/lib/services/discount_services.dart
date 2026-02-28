import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_services.dart';
import '../config/api_config.dart';

class DiscountService {
  static String get baseUrl => ApiConfig.path('/discount-codes');

  // Header có token
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Chưa đăng nhập');
    }

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. Lấy tất cả mã giảm giá (cho seller quản lý)
  static Future<List<Map<String, dynamic>>> getAllDiscountCodes() async {
    final url = Uri.parse(baseUrl);

    final response = await http.get(
      url,
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      print('Lỗi: ${response.body}');
      throw Exception('Không thể lấy danh sách mã giảm giá');
    }
  }

  // 2. Lấy mã giảm giá đang hoạt động (cho khách hàng)
  static Future<List<Map<String, dynamic>>> getActiveDiscountCodes() async {
    final url = Uri.parse('$baseUrl/active');

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

  // 3. Tạo mã giảm giá mới
  static Future<Map<String, dynamic>?> createDiscountCode({
    required String code,
    String? title,
    String? description,
    required String discountType, // "percent" hoặc "fixed"
    required double discountValue,
    double? minOrderValue,
    DateTime? startAt,
    DateTime? endAt,
    int? userId, // null = áp dụng cho tất cả user
  }) async {
    final url = Uri.parse(baseUrl);

    final body = {
      'code': code,
      'title': title,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_order_value': minOrderValue ?? 0,
      'start_at': startAt?.toIso8601String(),
      'end_at': endAt?.toIso8601String(),
      'user_id': userId,
    };

    final response = await http.post(
      url,
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Lỗi tạo mã giảm giá: ${response.body}');
      throw Exception(
          'Không thể tạo mã giảm giá: ${jsonDecode(response.body)['detail']}');
    }
  }

  // 4. Cập nhật mã giảm giá
  static Future<Map<String, dynamic>?> updateDiscountCode({
    required int discountCodeId,
    String? code,
    String? title,
    String? description,
    String? discountType,
    double? discountValue,
    double? minOrderValue,
    DateTime? startAt,
    DateTime? endAt,
    bool? active,
    int? userId,
  }) async {
    final url = Uri.parse('$baseUrl/$discountCodeId');

    final body = <String, dynamic>{};
    if (code != null) body['code'] = code;
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (discountType != null) body['discount_type'] = discountType;
    if (discountValue != null) body['discount_value'] = discountValue;
    if (minOrderValue != null) body['min_order_value'] = minOrderValue;
    if (startAt != null) body['start_at'] = startAt.toIso8601String();
    if (endAt != null) body['end_at'] = endAt.toIso8601String();
    if (active != null) body['active'] = active;
    if (userId != null) body['user_id'] = userId;

    final response = await http.put(
      url,
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Lỗi cập nhật mã giảm giá: ${response.body}');
      throw Exception('Không thể cập nhật mã giảm giá');
    }
  }

  // 5. Xóa mã giảm giá
  static Future<bool> deleteDiscountCode(int discountCodeId) async {
    final url = Uri.parse('$baseUrl/$discountCodeId');

    final response = await http.delete(
      url,
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Lỗi xóa mã giảm giá: ${response.body}');
      throw Exception('Không thể xóa mã giảm giá');
    }
  }

  // 6. Lấy chi tiết mã giảm giá
  static Future<Map<String, dynamic>?> getDiscountCode(
      int discountCodeId) async {
    final url = Uri.parse('$baseUrl/$discountCodeId');

    final response = await http.get(
      url,
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Lỗi: ${response.body}');
      throw Exception('Không tìm thấy mã giảm giá');
    }
  }

  // 7. Validate mã giảm giá
  static Future<Map<String, dynamic>> validateDiscountCode({
    required String code,
    required double cartTotal,
  }) async {
    final url = Uri.parse('$baseUrl/validate');

    final response = await http.post(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({
        'code': code,
        'cart_total': cartTotal,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Lỗi validate: ${response.body}');
      throw Exception('Không thể validate mã giảm giá');
    }
  }
}
