import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'auth_services.dart';

class PaymentServices {
  static const String baseUrl = "http://10.0.2.2:8000";

  // =============================
  // 🔐 Header có token
  // =============================
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception("Chưa đăng nhập");
    }

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // =============================
  // 1️⃣ Tạo PaymentIntent từ backend
  // =============================
  Future<Map<String, dynamic>> createPayment(int orderId) async {
    final url = Uri.parse("$baseUrl/api/payment/create");

    final response = await http.post(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({
        "order_id": orderId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Tạo payment thất bại: ${response.body}");
    }
  }

  // =============================
  // 2️⃣ Thanh toán bằng Stripe Payment Sheet
  // =============================
  Future<void> processPayment(int orderId) async {
    try {
      // 🔹 Tạo payment intent
      final paymentData = await createPayment(orderId);
      final clientSecret = paymentData["client_secret"];

      if (clientSecret == null) {
        throw Exception("Không nhận được client_secret");
      }

      // 🔹 Init Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: "Food Delivery App",
          style: ThemeMode.light,
        ),
      );

      // 🔹 Hiển thị Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      print("Thanh toán thành công 🎉");
    } on StripeException catch (e) {
      throw Exception("Thanh toán bị huỷ hoặc lỗi: ${e.error.message}");
    } catch (e) {
      throw Exception("Lỗi thanh toán: $e");
    }
  }

  // =============================
  // 3️⃣ Check trạng thái thanh toán
  // =============================
  Future<String> checkPaymentStatus(int orderId) async {
    final url = Uri.parse("$baseUrl/api/payment/check-status/$orderId");

    final response = await http.get(
      url,
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["status"];
    } else {
      throw Exception("Không check được trạng thái thanh toán");
    }
  }
}
