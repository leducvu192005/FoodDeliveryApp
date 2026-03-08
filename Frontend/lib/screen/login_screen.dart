import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/auth_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    if (loading) return;
    setState(() => loading = true);

    try {
      final role = await AuthService.login(
        emailCtrl.text.trim(),
        '',
        passCtrl.text.trim(),
      );

      if (!mounted) return;

      if (role != null) {
        switch (role) {
          case 'buyer':
            Navigator.pushReplacementNamed(context, '/buyer/layout');
            break;
          case 'seller':
            Navigator.pushReplacementNamed(context, '/buyer/layout');
            break;
          case 'shipper':
            Navigator.pushReplacementNamed(context, '/shipper/layout');
            break;
          case 'admin':
            Navigator.pushReplacementNamed(context, '/admin');
            break;
          case 'pending':
            _showPendingDialog();
            break;
          case 'fail':
            _showFailDialog();
            break;
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Role khong hop le')),
            );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sai tai khoan hoac mat khau')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dang nhap loi: $e\nAPI hien tai: ${ApiConfig.baseUrl}\nNeu la Android that, bam nut "API URL" de doi sang IP LAN may backend.',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.hourglass_top_rounded,
            size: 48, color: Colors.orange),
        title: const Text('Dang cho phe duyet'),
        content: const Text(
          'Tai khoan cua ban dang duoc phe duyet.\nVui long cho admin xac nhan.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dong'),
          ),
        ],
      ),
    );
  }

  void _showFailDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.cancel_rounded, size: 48, color: Colors.red),
        title: const Text('Tai khoan khong duoc phe duyet'),
        content: const Text(
          'Tai khoan cua ban da bi tu choi.\nVui long lien he admin de biet them chi tiet.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dong'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.deepOrange,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardInset),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Welcome to Food Delivery',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.food_bank,
                            size: 100,
                            color: Colors.deepOrange,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: emailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Email hoac so dien thoai',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: passCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.deepOrange,
                                alignment: Alignment.centerLeft,
                              ),
                              onPressed: () => Navigator.pushNamed(
                                  context, '/forgot-password'),
                              child: const Text('Quen mat khau?'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: loading ? null : login,
                            child: loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Login'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/register'),
                            child: const Text('Dang ky'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
