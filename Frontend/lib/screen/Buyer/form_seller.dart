import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/auth_services.dart';

class FormSeller extends StatefulWidget {
  const FormSeller({super.key});

  @override
  State<FormSeller> createState() => _FormSellerState();
}

class _FormSellerState extends State<FormSeller> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cccdCtrl = TextEditingController();
  final _shopNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _submitting = false;
  bool _loadingStatus = true;
  String? _currentStatus; // null, "pending", "yes", "no"

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cccdCtrl.dispose();
    _shopNameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Chua dang nhap');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _checkStatus() async {
    setState(() => _loadingStatus = true);
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.path('/form-seller/status')),
        headers: await _authHeaders(),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _currentStatus = body['status'];
          _loadingStatus = false;
        });
      } else {
        setState(() {
          _currentStatus = null;
          _loadingStatus = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentStatus = null;
          _loadingStatus = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.path('/form-seller/register')),
        headers: await _authHeaders(),
        body: jsonEncode({
          'name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'cccd': _cccdCtrl.text.trim(),
          'name_shop': _shopNameCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Dang ky thanh cong! Vui long cho admin duyet.')),
        );
        setState(() => _currentStatus = 'pending');
      } else {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        final detail = body['detail'] ?? 'Dang ky that bai';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(detail.toString())),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loi: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetForm() {
    _nameCtrl.clear();
    _phoneCtrl.clear();
    _cccdCtrl.clear();
    _shopNameCtrl.clear();
    _addressCtrl.clear();
    setState(() => _currentStatus = null);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE67E22);
    const pageBg = Color(0xFFFFFAF0);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        title: const Text('Dang ky tro thanh Seller'),
      ),
      body: _loadingStatus
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(accent),
    );
  }

  Widget _buildBody(Color accent) {
    if (_currentStatus == 'pending') {
      return _buildStatusScreen(
        icon: Icons.hourglass_top_rounded,
        iconColor: Colors.orange,
        title: 'Dang cho duyet',
        message: 'Ho so cua ban dang duoc xem xet.\nVui long cho admin duyet.',
        actions: [],
      );
    }

    if (_currentStatus == 'yes') {
      return _buildStatusScreen(
        icon: Icons.check_circle_rounded,
        iconColor: Colors.green,
        title: 'Chuc mung!',
        message:
            'Ban da tro thanh nguoi ban hang.\nHay chuyen sang giao dien Seller de bat dau.',
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/seller',
                (route) => false,
              );
            },
            icon: const Icon(Icons.store_rounded),
            label: const Text('Chuyen sang Seller'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      );
    }

    if (_currentStatus == 'no') {
      return _buildStatusScreen(
        icon: Icons.cancel_rounded,
        iconColor: Colors.red,
        title: 'Ho so bi tu choi',
        message:
            'Ho so dang ky cua ban da bi tu choi.\nBan co the gui lai don dang ky moi.',
        actions: [
          ElevatedButton.icon(
            onPressed: _resetForm,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Gui lai don dang ky'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE67E22),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      );
    }

    // status == null → show registration form
    return _buildRegistrationForm(const Color(0xFFE67E22));
  }

  Widget _buildStatusScreen({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required List<Widget> actions,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 72, color: iconColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 32),
              ...actions,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm(Color accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.store_rounded, size: 48, color: accent),
                  const SizedBox(height: 8),
                  const Text(
                    'Thong tin dang ky Seller',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    controller: _nameCtrl,
                    label: 'Ho ten',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Vui long nhap ho ten'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _phoneCtrl,
                    label: 'So dien thoai',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Vui long nhap SDT'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _cccdCtrl,
                    label: 'Can cuoc cong dan',
                    icon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Vui long nhap CCCD'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _shopNameCtrl,
                    label: 'Ten quan',
                    icon: Icons.storefront_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Vui long nhap ten quan'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _addressCtrl,
                    label: 'Dia chi quan',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Vui long nhap dia chi'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Gui don dang ky',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFE67E22)),
        filled: true,
        fillColor: const Color(0xFFFFF6EA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
