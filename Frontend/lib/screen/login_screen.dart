import 'dart:io';

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
  final sdtCtrl = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    if (loading) return;
    setState(() => loading = true);

    try {
      final role = await AuthService.login(
        emailCtrl.text.trim(),
        sdtCtrl.text.trim(),
        passCtrl.text.trim(),
      );

      if (!mounted) return;

      if (role != null) {
        switch (role) {
          case 'buyer':
            Navigator.pushReplacementNamed(context, '/buyer/layout');
            break;
          case 'seller':
            Navigator.pushReplacementNamed(context, '/seller');
            break;
          case 'shipper':
            Navigator.pushReplacementNamed(context, '/shipper');
            break;
          case 'admin':
            Navigator.pushReplacementNamed(context, '/admin');
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
            'Dang nhap loi: $e\nAPI: ${ApiConfig.baseUrl}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            height: 500,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome to Food Delivery',
                  style: TextStyle(fontSize: 22),
                ),
                const Icon(
                  Icons.food_bank,
                  size: 100,
                  color: Colors.deepOrange,
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email or số diện thoại',
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
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: loading ? null : login,
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('Dang ky'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
