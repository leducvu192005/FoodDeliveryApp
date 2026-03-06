import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import 'auth_services.dart';
import '../config/api_config.dart';

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

  // ==============================
  // SEPAY PAYMENT METHODS
  // ==============================

  /// Tạo thanh toán Sepay (QR Code chuyển khoản ngân hàng)
  Future<Map<String, dynamic>> createSepayPayment(int orderId) async {
    final url = Uri.parse("$baseUrl/api/sepay/create");

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

  /// Xử lý thanh toán Sepay - hiển thị QR code cho người dùng
  Future<void> processSepayPayment(
    BuildContext context,
    int orderId,
  ) async {
    try {
      final paymentData = await createSepayPayment(orderId);

      final qrUrl = paymentData["qr_url"];
      final transactionId = paymentData["transaction_id"];
      final amount = paymentData["amount"];
      final transferContent = paymentData["transfer_content"];
      final bankCode = paymentData["bank_code"];
      final accountNumber = paymentData["account_number"];
      final accountName = paymentData["account_name"];

      if (qrUrl == null || transactionId == null) {
        throw Exception("Khong nhan duoc thong tin thanh toan");
      }

      // Hiển thị dialog với QR code
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

  /// Kiểm tra trạng thái thanh toán
  Future<String> checkPaymentStatus(int orderId) async {
    final url = Uri.parse("$baseUrl/api/sepay/check-status/$orderId");

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

  /// Hủy thanh toán Sepay
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

  // ==============================
  // STRIPE PAYMENT METHODS (Legacy)
  // ==============================

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
}

// ==============================
// SEPAY PAYMENT DIALOG
// ==============================
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
    // Bắt đầu tự động kiểm tra payment status sau 5 giây
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _startAutoChecking();
      }
    });
  }

  void _startAutoChecking() async {
    if (_autoChecking) return;
    setState(() {
      _autoChecking = true;
    });

    try {
      final paymentService = PaymentServices();
      // Tự động check mỗi 3 giây, tối đa 20 lần (60 giây)
      for (int i = 0; i < 20; i++) {
        if (!mounted) return;

        final status = await paymentService.checkPaymentStatus(widget.orderId);
        if (status == 'paid') {
          if (!mounted) return;
          // Tự động đóng dialog khi thanh toán thành công
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
      final status = await paymentService.checkPaymentStatus(widget.orderId);

      if (status == 'paid') {
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Chua nhan duoc xac nhan thanh toan. Vui long doi them hoac thu lai.'),
          ),
        );
      }
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
        'Thanh toán qua Chuyển khoản',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR Code
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

            // Thông tin chuyển khoản
            _InfoRow(label: 'Ngân hàng:', value: widget.bankCode),
            _InfoRow(label: 'Số tài khoản:', value: widget.accountNumber),
            _InfoRow(label: 'Tên tài khoản:', value: widget.accountName),
            _InfoRow(
              label: 'Số tiền:',
              value: '\$${widget.amount.toStringAsFixed(2)}',
              valueColor: accent,
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            const Text(
              'Nội dung chuyển khoản:',
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
              '⚠️ Lưu ý: Vui lòng nhập CHÍNH XÁC nội dung chuyển khoản để hệ thống tự động xác nhận.',
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
                    'Đang tự động kiểm tra thanh toán...',
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
          child: const Text('Hủy'),
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
              : const Text('Đã chuyển khoản'),
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
