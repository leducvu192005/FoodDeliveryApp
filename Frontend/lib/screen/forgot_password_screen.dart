import 'package:flutter/material.dart';
import '../services/auth_services.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  int _step = 0; // 0: email, 1: otp, 2: new password
  bool _loading = false;

  Future<void> _sendOtp() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack('Vui long nhap email');
      return;
    }
    setState(() => _loading = true);
    try {
      final error = await AuthService.forgotPassword(email);
      if (!mounted) return;
      if (error == null) {
        setState(() => _step = 1);
        _snack('OTP da duoc gui den email cua ban');
      } else {
        _snack(error);
      }
    } catch (e) {
      if (mounted) _snack('Loi: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _verifyOtp() {
    if (otpCtrl.text.trim().length != 6) {
      _snack('Vui long nhap ma OTP 6 so');
      return;
    }
    setState(() => _step = 2);
  }

  Future<void> _resetPassword() async {
    final newPass = newPassCtrl.text.trim();
    final confirmPass = confirmPassCtrl.text.trim();

    if (newPass.isEmpty || newPass.length < 6) {
      _snack('Mat khau phai co it nhat 6 ky tu');
      return;
    }
    if (newPass != confirmPass) {
      _snack('Mat khau xac nhan khong khop');
      return;
    }

    setState(() => _loading = true);
    try {
      final error = await AuthService.resetPassword(
        emailCtrl.text.trim(),
        otpCtrl.text.trim(),
        newPass,
      );
      if (!mounted) return;
      if (error == null) {
        _showSuccessDialog();
      } else {
        _snack(error);
      }
    } catch (e) {
      if (mounted) _snack('Loi: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.check_circle, size: 48, color: Colors.green),
        title: const Text('Thanh cong'),
        content: const Text(
          'Mat khau da duoc dat lai.\nVui long dang nhap lai.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Dang nhap'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    otpCtrl.dispose();
    newPassCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange,
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Quen mat khau'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _step == 0
                        ? Icons.email_outlined
                        : _step == 1
                            ? Icons.pin_outlined
                            : Icons.lock_reset,
                    size: 64,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _step == 0
                        ? 'Nhap email de nhan ma OTP'
                        : _step == 1
                            ? 'Nhap ma OTP da gui den email'
                            : 'Nhap mat khau moi',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Step indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final active = i <= _step;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              active ? Colors.deepOrange : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  if (_step == 0) ...[
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Gui ma OTP',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                  if (_step == 1) ...[
                    TextField(
                      controller: otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24,
                          letterSpacing: 8,
                          fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: 'Ma OTP',
                        prefixIcon: Icon(Icons.pin_outlined),
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _sendOtp,
                        child: const Text('Gui lai OTP'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Tiep tuc',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                  if (_step == 2) ...[
                    TextField(
                      controller: newPassCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mat khau moi',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPassCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Xac nhan mat khau',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Dat lai mat khau',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
