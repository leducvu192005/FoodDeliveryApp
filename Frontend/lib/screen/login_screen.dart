import 'package:flutter/material.dart';
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
  void login() async {
    setState(() => loading = true);

    final role = await AuthService.login(
      emailCtrl.text.trim(),
      passCtrl.text.trim(),
    );

    setState(() => loading = false);

    if (!mounted) return;

    if (role != null) {
      switch (role) {
        case "buyer":
          Navigator.pushReplacementNamed(context, "/buyer/layout");
          break;
        case "seller":
          Navigator.pushReplacementNamed(context, "/seller");
          break;
        case "shipper":
          Navigator.pushReplacementNamed(context, "/shipper");
          break;
        case "admin":
          Navigator.pushReplacementNamed(context, "/admin");
          break;
        default:
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Role không hợp lệ")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sai tài khoản hoặc mật khẩu")),
      );
    }
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
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Wellcome to Food Delivery",
                  style: TextStyle(fontSize: 22),
                ),
                const Icon(
                  Icons.food_bank,
                  size: 100,
                  color: Colors.deepOrange,
                ),
                TextField(
                  controller: emailCtrl,
                  style: const TextStyle(color: Colors.black, fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: loading ? null : login,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text("Login"),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, "/register"),
                  child: const Text("Đăng ký"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
