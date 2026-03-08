import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/auth_services.dart';

class FormShipper extends StatefulWidget {
  const FormShipper({super.key});

  @override
  State<FormShipper> createState() => _FormShipperState();
}

class _FormShipperState extends State<FormShipper> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cccdCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();

  bool _submitting = false;
  bool _loadingStatus = true;
  String? _currentStatus;

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
    _vehicleCtrl.dispose();
    _licenseCtrl.dispose();
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
        Uri.parse(ApiConfig.path('/form-shipper/status')),
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
        Uri.parse(ApiConfig.path('/form-shipper/register')),
        headers: await _authHeaders(),
        body: jsonEncode({
          'name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'cccd': _cccdCtrl.text.trim(),
          'vehicle_registration': _vehicleCtrl.text.trim(),
          'license': _licenseCtrl.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dang ky thanh cong! Vui long cho admin duyet.'),
          ),
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
    _vehicleCtrl.clear();
    _licenseCtrl.clear();
    setState(() => _currentStatus = null);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Colors.teal;
    const pageBg = Color(0xFFFFFAF0);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        title: const Text('Dang ky tro thanh Shipper'),
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
        actions: const [],
      );
    }

    if (_currentStatus == 'yes') {
      return _buildStatusScreen(
        icon: Icons.check_circle_rounded,
        iconColor: Colors.green,
        title: 'Chuc mung!',
        message:
            'Ban da tro thanh shipper.\nHay dang nhap giao dien Shipper de bat dau.',
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/shipper/layout',
                (route) => false,
              );
            },
            icon: const Icon(Icons.delivery_dining),
            label: const Text('Chuyen sang Shipper'),
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
              backgroundColor: accent,
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

    return _buildRegistrationForm(accent);
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
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
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
                  Icon(Icons.delivery_dining, size: 48, color: accent),
                  const SizedBox(height: 8),
                  const Text(
                    'Thong tin dang ky Shipper',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                    controller: _vehicleCtrl,
                    label: 'Dang ky xe',
                    icon: Icons.directions_bike_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Vui long nhap dang ky xe'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _licenseCtrl,
                    label: 'So bang lai',
                    icon: Icons.credit_card_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Vui long nhap bang lai'
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
        prefixIcon: Icon(icon, color: Colors.teal),
        filled: true,
        fillColor: const Color(0xFFEFFAF7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
