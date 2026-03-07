import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ShipperApiClient {
  Future<dynamic> get(String path, {String? token}) async {
    final res = await http.get(
      Uri.parse(ApiConfig.path(path)),
      headers: _headers(token),
    );
    return _handleResponse(res);
  }

  Future<dynamic> post(String path,
      {Map<String, dynamic>? body, String? token}) async {
    final res = await http.post(
      Uri.parse(ApiConfig.path(path)),
      headers: _headers(token),
      body: jsonEncode(body ?? {}),
    );
    return _handleResponse(res);
  }

  Future<dynamic> put(String path,
      {Map<String, dynamic>? body, String? token}) async {
    final res = await http.put(
      Uri.parse(ApiConfig.path(path)),
      headers: _headers(token),
      body: jsonEncode(body ?? {}),
    );
    return _handleResponse(res);
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _handleResponse(http.Response res) {
    dynamic payload;
    if (res.body.isNotEmpty) {
      payload = jsonDecode(res.body);
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return payload;
    }

    String message = 'Request failed (${res.statusCode})';
    if (payload is Map<String, dynamic> && payload['detail'] != null) {
      message = payload['detail'].toString();
    } else if (res.body.isNotEmpty) {
      message = res.body;
    }
    throw Exception(message);
  }
}
