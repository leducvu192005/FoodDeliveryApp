import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_services.dart';

class PaymentServices {
  static String get baseUrl => ApiConfig.baseUrl;

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

  Future<Map<String, dynamic>> createSepayPayment(int orderId) async {
    final url = Uri.parse("$baseUrl/api/sepay/create");

    final response = await http.post(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({"order_id": orderId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception("Tao payment that bai: ${response.body}");
  }

  Future<void> processSepayPayment(
    BuildContext context,
    int orderId,
  ) async {
    try {
      final paymentData = await createSepayPayment(orderId);

      final qrUrl = paymentData["qr_url"]?.toString();
      final transactionId = paymentData["transaction_id"]?.toString();
      final amount = (paymentData["amount"] as num?)?.toDouble() ?? 0;
      final transferContent = paymentData["transfer_content"]?.toString() ?? "";
      final bankCode = paymentData["bank_code"]?.toString() ?? "";
      final accountNumber = paymentData["account_number"]?.toString() ?? "";
      final accountName = paymentData["account_name"]?.toString() ?? "";

      if (qrUrl == null || qrUrl.isEmpty || transactionId == null || transactionId.isEmpty) {
        throw Exception("Khong nhan duoc thong tin thanh toan");
      }

      if (!context.mounted) return;

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _SepayPaymentDialog(
          qrUrl: qrUrl,
          transactionId: transactionId,
          amount: amount,
          transferContent: transferContent,
          bankCode: bankCode,
          accountNumber: accountNumber,
          accountName: accountName,
          orderId: orderId,
        ),
      );

      if (result != true) {
        throw Exception("Payment canceled by user");
      }
    } catch (e, st) {
      debugPrint("Sepay payment error: ${e.runtimeType} - $e");
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  Future<String> checkSepayPaymentStatus(int orderId) async {
    final url = Uri.parse("$baseUrl/api/sepay/check-status/$orderId");

    final response = await http.get(
      url,
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data["status"]?.toString() ?? "pending";
    }
    throw Exception("Khong check duoc trang thai thanh toan");
  }

  Future<void> cancelSepayPayment(int orderId) async {
    final url = Uri.parse("$baseUrl/api/sepay/cancel/$orderId");

    final response = await http.post(
      url,
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception("Khong the huy thanh toan");
    }
  }

  Future<Map<String, dynamic>> createPayment(int orderId) async {
    final url = Uri.parse("$baseUrl/api/payment/create");

    final response = await http.post(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({"order_id": orderId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception("Tao payment that bai: ${response.body}");
  }

  Future<void> processPaymentSheet(String clientSecret) async {
    try {
      final pubKey = Stripe.publishableKey;
      if (pubKey.trim().isEmpty) {
        throw Exception("Stripe publishableKey is not set in main.dart");
      }

      await Stripe.instance.applySettings();

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

  Future<Map<String, dynamic>> confirmCheckout(int checkoutId) async {
    final url = Uri.parse("$baseUrl/api/payment/confirm-checkout/$checkoutId");

    final response = await http.post(
      url,
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception("Khong xac nhan duoc thanh toan: ${response.body}");
  }
}

class _SepayPaymentDialog extends StatefulWidget {
  final String qrUrl;
  final String transactionId;
  final double amount;
  final String transferContent;
  final String bankCode;
  final String accountNumber;
  final String accountName;
  final int orderId;

  const _SepayPaymentDialog({
    required this.qrUrl,
    required this.transactionId,
    required this.amount,
    required this.transferContent,
    required this.bankCode,
    required this.accountNumber,
    required this.accountName,
    required this.orderId,
  });

  @override
  State<_SepayPaymentDialog> createState() => _SepayPaymentDialogState();
}

class _SepayPaymentDialogState extends State<_SepayPaymentDialog> {
  bool _isChecking = false;
  bool _autoChecking = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _startAutoChecking();
      }
    });
  }

  Future<void> _startAutoChecking() async {
    if (_autoChecking) return;
    setState(() {
      _autoChecking = true;
    });

    try {
      final paymentService = PaymentServices();
      for (int i = 0; i < 20; i++) {
        if (!mounted) return;

        final status = await paymentService.checkSepayPaymentStatus(widget.orderId);
        if (status == 'paid') {
          if (!mounted) return;
          Navigator.of(context).pop(true);
          return;
        }

        await Future.delayed(const Duration(seconds: 3));
      }
    } catch (e) {
      debugPrint('Auto check error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _autoChecking = false;
        });
      }
    }
  }

  Future<void> _checkPaymentStatus() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final paymentService = PaymentServices();
      final status = await paymentService.checkSepayPaymentStatus(widget.orderId);

      if (status == 'paid') {
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chua nhan duoc xac nhan thanh toan. Vui long doi them hoac thu lai.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE67E22);

    return AlertDialog(
      title: const Text(
        'Thanh toan qua Chuyen khoan',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(
                widget.qrUrl,
                width: 250,
                height: 250,
                errorBuilder: (_, __, ___) => Container(
                  width: 250,
                  height: 250,
                  color: Colors.grey[200],
                  child: const Icon(Icons.qr_code, size: 100),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _InfoRow(label: 'Ngan hang:', value: widget.bankCode),
            _InfoRow(label: 'So tai khoan:', value: widget.accountNumber),
            _InfoRow(label: 'Ten tai khoan:', value: widget.accountName),
            _InfoRow(
              label: 'So tien:',
              value: '\$${widget.amount.toStringAsFixed(2)}',
              valueColor: accent,
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Noi dung chuyen khoan:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent),
              ),
              child: Text(
                widget.transferContent,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Luu y: Vui long nhap dung noi dung chuyen khoan de he thong tu dong xac nhan.',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
            const SizedBox(height: 8),
            if (_autoChecking)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Dang tu dong kiem tra thanh toan...',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isChecking
              ? null
              : () async {
                  try {
                    await PaymentServices().cancelSepayPayment(widget.orderId);
                  } catch (e) {
                    debugPrint('Cancel error: $e');
                  }
                  if (mounted) {
                    Navigator.of(context).pop(false);
                  }
                },
          child: const Text('Huy'),
        ),
        ElevatedButton(
          onPressed: _isChecking ? null : _checkPaymentStatus,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
          ),
          child: _isChecking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Da chuyen khoan'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
