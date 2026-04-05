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
      final result = await AuthService.login(
        emailCtrl.text.trim(),
        '',
        passCtrl.text.trim(),
      );

      if (!mounted) return;

      if (result != null) {
        await _handleLoginResult(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sai tài khoản hoặc mật khẩu')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đăng nhập: $e\nAPI: ${ApiConfig.baseUrl}'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _handleLoginResult(Map<String, String?> result) async {
    final role = result['role']?.trim().toLowerCase();
    final status = result['status']?.trim().toLowerCase();

    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin');
      return;
    }

    if (role == 'seller') {
      Navigator.pushReplacementNamed(context, '/seller');
      return;
    }

    if (role == 'shipper') {
      Navigator.pushReplacementNamed(context, '/shipper/layout');
      return;
    }

    if (role == 'all' || status == 'done') {
      _showTripleRoleDialog();
      return;
    }

    // Keep compatibility with accounts that are approved but still return
    // role=buyer from the backend until a role switch happens.
    if (role == 'buyer' && status == 'done_seller') {
      await _switchRoleAfterLogin('seller', '/seller');
      return;
    }

    if (role == 'buyer' && status == 'done_shipper') {
      await _switchRoleAfterLogin('shipper', '/shipper/layout');
      return;
    }

    Navigator.pushReplacementNamed(context, '/buyer/layout');
  }

  Future<void> _switchRoleAfterLogin(String role, String route) async {
    final res = await AuthService.switchRole(role);

    if (!mounted) return;

    if (res != null && res['error'] == null) {
      Navigator.pushReplacementNamed(context, route);
      return;
    }

    Navigator.pushReplacementNamed(context, '/buyer/layout');
  }

  void _showTripleRoleDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.person, size: 48, color: Colors.deepOrange),
        title: const Text('Chọn vai trò đăng nhập'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogButton(
              icon: Icons.shopping_bag,
              label: 'Người mua',
              color: Colors.deepOrange,
              onPressed: () => _handleSwitchRole('buyer', '/buyer/layout', ctx),
            ),
            const SizedBox(height: 12),
            _buildDialogButton(
              icon: Icons.store,
              label: 'Người bán',
              color: Colors.green,
              onPressed: () => _handleSwitchRole('seller', '/seller', ctx),
            ),
            const SizedBox(height: 12),
            _buildDialogButton(
              icon: Icons.delivery_dining,
              label: 'Tài xế',
              color: Colors.blue,
              onPressed: () =>
                  _handleSwitchRole('shipper', '/shipper/layout', ctx),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSwitchRole(
    String role,
    String route,
    BuildContext dialogCtx,
  ) async {
    Navigator.of(dialogCtx).pop();
    setState(() => loading = true);
    final res = await AuthService.switchRole(role);

    if (!mounted) return;

    setState(() => loading = false);

    if (res != null && res['error'] == null) {
      Navigator.pushReplacementNamed(context, route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?['error'] ?? 'Không thể chuyển vai trò')),
      );
    }
  }

  Widget _buildDialogButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onPressed,
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
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Welcome to Food Delivery',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(
                            Icons.food_bank,
                            size: 100,
                            color: Colors.deepOrange,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: emailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: passCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Mật khẩu',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                '/forgot-password',
                              ),
                              child: const Text('Quên mật khẩu?'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: loading ? null : login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                              ),
                              child: loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Đăng nhập',
                                      style: TextStyle(color: Colors.white),
                                    ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/register'),
                            child: const Text(
                              'Chưa có tài khoản? Đăng ký ngay',
                            ),
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
