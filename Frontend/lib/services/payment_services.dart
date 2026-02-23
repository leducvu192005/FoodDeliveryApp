import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import 'auth_services.dart';

class PaymentServices {
  static const String baseUrl = "http://10.0.2.2:8000";

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception("Chua dang nhap");
    }

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

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
    }
    throw Exception("Tao payment that bai: ${response.body}");
  }

  Future<void> processPayment(int orderId) async {
    try {
      final pubKey = Stripe.publishableKey;
      if (pubKey.trim().isEmpty) {
        throw Exception(
          "Stripe publishableKey is not set in main.dart",
        );
      }

      await Stripe.instance.applySettings();

      final paymentData = await createPayment(orderId);
      final clientSecret = paymentData["client_secret"];

      if (clientSecret == null) {
        throw Exception("Khong nhan duoc client_secret");
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: "Food Delivery App",
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e, st) {
      final message = e.error.message;
      final errorCode = e.error.code.toString().toLowerCase();
      debugPrint("StripeException: $errorCode - $message");
      debugPrintStack(stackTrace: st);

      final fullMsg = "$errorCode $message".toLowerCase();
      if (fullMsg.contains("canceled") || fullMsg.contains("cancelled")) {
        throw Exception("Payment canceled by user");
      }
      throw Exception("Stripe payment failed: ${message ?? e.toString()}");
    } catch (e, st) {
      debugPrint("Unhandled payment error: ${e.runtimeType} - $e");
      debugPrintStack(stackTrace: st);
      throw Exception("Payment error: ${e.runtimeType}: $e");
    }
  }

  Future<String> checkPaymentStatus(int orderId) async {
    final url = Uri.parse("$baseUrl/api/payment/check-status/$orderId");

    final response = await http.get(
      url,
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["status"];
    }
    throw Exception("Khong check duoc trang thai thanh toan");
  }
}
