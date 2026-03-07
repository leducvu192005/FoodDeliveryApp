import 'package:flutter/material.dart';

import '../services/auth_services.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final sdtCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final cccdCtrl = TextEditingController();
  final vehicleRegCtrl = TextEditingController();
  final licenseCtrl = TextEditingController();
  final shopNameCtrl = TextEditingController();
  final shopAddressCtrl = TextEditingController();

  String role = 'buyer';
  bool loading = false;

  Future<void> register() async {
    if (nameCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        sdtCtrl.text.isEmpty ||
        passCtrl.text.isEmpty) {
      _showMsg('Vui long nhap day du thong tin');
      return;
    }

    if (role == 'shipper') {
      if (cccdCtrl.text.isEmpty ||
          vehicleRegCtrl.text.isEmpty ||
          licenseCtrl.text.isEmpty) {
        _showMsg('Vui long nhap CCCD, dang ky xe va so bang lai');
        return;
      }
    }

    if (role == 'seller') {
      if (cccdCtrl.text.isEmpty ||
          shopNameCtrl.text.isEmpty ||
          shopAddressCtrl.text.isEmpty) {
        _showMsg('Vui long nhap CCCD, ten quan va dia chi quan');
        return;
      }
    }

    setState(() => loading = true);

    final error = await AuthService.register(
      nameCtrl.text.trim(),
      emailCtrl.text.trim(),
      sdtCtrl.text.trim(),
      passCtrl.text.trim(),
      role,
      cccd: cccdCtrl.text.trim(),
      vehicleRegistration: vehicleRegCtrl.text.trim(),
      license: licenseCtrl.text.trim(),
      nameShop: shopNameCtrl.text.trim(),
      addressShop: shopAddressCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => loading = false);

    if (error == null) {
      if (role == 'buyer') {
        _showMsg('Dang ky thanh cong!');
      } else {
        _showMsg('Dang ky thanh cong! Tai khoan cua ban dang cho duyet.');
      }
      Navigator.pop(context);
    } else {
      _showMsg(error);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    sdtCtrl.dispose();
    passCtrl.dispose();
    cccdCtrl.dispose();
    vehicleRegCtrl.dispose();
    licenseCtrl.dispose();
    shopNameCtrl.dispose();
    shopAddressCtrl.dispose();
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
                          const Text(
                            'Nhap thong tin de dang ky',
                            style: TextStyle(fontSize: 22),
                          ),
                          const Icon(Icons.food_bank,
                              size: 80, color: Colors.deepOrange),
                          const SizedBox(height: 20),
                          TextField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: emailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: sdtCtrl,
                            decoration: const InputDecoration(
                              labelText: 'So dien thoai',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
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
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: role,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'buyer', child: Text('Buyer')),
                              DropdownMenuItem(
                                  value: 'seller', child: Text('Seller')),
                              DropdownMenuItem(
                                  value: 'shipper', child: Text('Shipper')),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => role = v);
                            },
                          ),
                          // === Shipper extra fields ===
                          if (role == 'shipper') ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const Text(
                              'Thong tin Shipper',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepOrange,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: cccdCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Can cuoc cong dan (CCCD)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: vehicleRegCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Dang ky xe',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.directions_car_outlined),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: licenseCtrl,
                              decoration: const InputDecoration(
                                labelText: 'So bang lai xe',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.credit_card_outlined),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                          // === Seller extra fields ===
                          if (role == 'seller') ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const Text(
                              'Thong tin Seller',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepOrange,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: cccdCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Can cuoc cong dan (CCCD)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: shopNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Ten quan',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.storefront_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: shopAddressCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Dia chi quan',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on_outlined),
                              ),
                            ),
                          ],
                          if (role != 'buyer') ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.orange, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tai khoan Seller/Shipper can duoc admin phe duyet truoc khi su dung.',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.orange),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: loading ? null : register,
                              child: loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Text('Register'),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Da co tai khoan? Dang nhap'),
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
