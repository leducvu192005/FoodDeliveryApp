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

  // Seller fields
  final shopNameCtrl = TextEditingController();
  final shopAddressCtrl = TextEditingController();
  final sellerCccdCtrl = TextEditingController();

  // Shipper fields
  final shipperCccdCtrl = TextEditingController();
  final vehicleRegCtrl = TextEditingController();
  final licenseCtrl = TextEditingController();

  String _selectedRole = 'buyer';
  bool loading = false;

  Future<void> register() async {
    if (nameCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        sdtCtrl.text.isEmpty ||
        passCtrl.text.isEmpty) {
      _showMsg('Vui long nhap day du thong tin');
      return;
    }

    if (_selectedRole == 'seller') {
      if (shopNameCtrl.text.isEmpty ||
          shopAddressCtrl.text.isEmpty ||
          sellerCccdCtrl.text.isEmpty) {
        _showMsg('Vui long nhap day du thong tin seller');
        return;
      }
    }

    if (_selectedRole == 'shipper') {
      if (shipperCccdCtrl.text.isEmpty ||
          vehicleRegCtrl.text.isEmpty ||
          licenseCtrl.text.isEmpty) {
        _showMsg('Vui long nhap day du thong tin shipper');
        return;
      }
    }

    setState(() => loading = true);

    final error = await AuthService.register(
      nameCtrl.text.trim(),
      emailCtrl.text.trim(),
      sdtCtrl.text.trim(),
      passCtrl.text.trim(),
      _selectedRole,
      cccd: _selectedRole == 'seller'
          ? sellerCccdCtrl.text.trim()
          : _selectedRole == 'shipper'
              ? shipperCccdCtrl.text.trim()
              : null,
      nameShop: _selectedRole == 'seller' ? shopNameCtrl.text.trim() : null,
      addressShop:
          _selectedRole == 'seller' ? shopAddressCtrl.text.trim() : null,
      vehicleRegistration:
          _selectedRole == 'shipper' ? vehicleRegCtrl.text.trim() : null,
      license: _selectedRole == 'shipper' ? licenseCtrl.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => loading = false);

    if (error == null) {
      final msg = _selectedRole == 'buyer'
          ? 'Dang ky thanh cong!'
          : 'Dang ky thanh cong! Vui long cho admin duyet.';
      _showMsg(msg);
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
    shopNameCtrl.dispose();
    shopAddressCtrl.dispose();
    sellerCccdCtrl.dispose();
    shipperCccdCtrl.dispose();
    vehicleRegCtrl.dispose();
    licenseCtrl.dispose();
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
                              labelText: 'Ho va ten',
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
                              labelText: 'Mat khau',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 16),

                          // === Role picker ===

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
                                  : const Text('Dang ky'),
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

  Widget _buildRoleChip(String role, String label) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepOrange : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
