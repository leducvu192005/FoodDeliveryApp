import 'dart:convert';
import 'package:http/http.dart' as http;

class ShipperServices {
  final String baseUrl = 'http://10.0.2:8000/api/shipper';
  final String token;
  ShipperServices({required this.token});
  Future<bool> toggleOnline() async {
    final url = Uri.parse('$baseUrl/toggle-online');
    final response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['is_online'];
    }
    throw Exception('Failed to toggle online status: ${response.body}');
  }
}
