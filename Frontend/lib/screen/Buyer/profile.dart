import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/auth_services.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.path('/profile/me')),
        headers: await _authHeaders(),
      );

      if (response.statusCode == 200) {
        _profile =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else {
        _profile = null;
      }
    } catch (_) {
      _profile = null;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<bool> _updateProfileField(Map<String, dynamic> payload) async {
    if (_saving) return false;

    setState(() {
      _saving = true;
    });

    try {
      final response = await http.put(
        Uri.parse(ApiConfig.path('/profile/me')),
        headers: await _authHeaders(),
        body: jsonEncode(payload),
      );

      if (!mounted) return false;

      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        setState(() {
          _profile = (data['profile'] as Map<String, dynamic>?) ?? data;
        });
        return true;
      }

      _showMessage('Khong the cap nhat: ${utf8.decode(response.bodyBytes)}');
      return false;
    } catch (e) {
      _showMessage('Loi cap nhat: $e');
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<bool> _updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_saving) return false;

    setState(() {
      _saving = true;
    });

    try {
      final response = await http.put(
        Uri.parse(ApiConfig.path('/profile/me/password')),
        headers: await _authHeaders(),
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (!mounted) return false;

      if (response.statusCode == 200) {
        return true;
      }

      _showMessage(
          'Khong the cap nhat mat khau: ${utf8.decode(response.bodyBytes)}');
      return false;
    } catch (e) {
      _showMessage('Loi cap nhat mat khau: $e');
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<String?> _showEditFieldDialog({
    required String title,
    required String label,
    required String initialValue,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) async {
    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            autofocus: true,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Huy'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Luu'),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  Future<_PasswordPayload?> _showChangePasswordDialog() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<_PasswordPayload>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cap nhat mat khau'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mat khau hien tai',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mat khau moi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nhap lai mat khau moi',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Huy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(
                _PasswordPayload(
                  currentPassword: currentController.text.trim(),
                  newPassword: newController.text.trim(),
                  confirmPassword: confirmController.text.trim(),
                ),
              );
            },
            child: const Text('Luu'),
          ),
        ],
      ),
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    return result;
  }

  Future<void> _handleUpdateName() async {
    final value = await _showEditFieldDialog(
      title: 'Cap nhat ten',
      label: 'Ten',
      initialValue: (_profile?['name'] ?? '').toString(),
      icon: Icons.person_outline_rounded,
    );
    if (value == null) return;
    if (value.isEmpty) {
      _showMessage('Ten khong duoc de trong');
      return;
    }
    final ok = await _updateProfileField({'name': value});
    if (ok) _showMessage('Cap nhat ten thanh cong');
  }

  Future<void> _handleUpdatePhone() async {
    final value = await _showEditFieldDialog(
      title: 'Cap nhat so dien thoai',
      label: 'So dien thoai',
      initialValue: (_profile?['sdt'] ?? '').toString(),
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
    );
    if (value == null) return;
    if (value.isEmpty) {
      _showMessage('So dien thoai khong duoc de trong');
      return;
    }
    final ok = await _updateProfileField({'sdt': value});
    if (ok) _showMessage('Cap nhat so dien thoai thanh cong');
  }

  Future<void> _handleUpdateAddress() async {
    final value = await _showEditFieldDialog(
      title: 'Cap nhat dia chi',
      label: 'Dia chi giao hang',
      initialValue: (_profile?['live'] ?? '').toString(),
      icon: Icons.location_on_outlined,
      maxLines: 2,
    );
    if (value == null) return;
    final ok = await _updateProfileField({'live': value});
    if (ok) _showMessage('Cap nhat dia chi thanh cong');
  }

  Future<void> _handleUpdatePassword() async {
    final payload = await _showChangePasswordDialog();
    if (payload == null) return;

    if (payload.currentPassword.isEmpty ||
        payload.newPassword.isEmpty ||
        payload.confirmPassword.isEmpty) {
      _showMessage('Vui long nhap day du thong tin');
      return;
    }
    if (payload.newPassword != payload.confirmPassword) {
      _showMessage('Mat khau moi khong khop');
      return;
    }

    final ok = await _updatePassword(
      currentPassword: payload.currentPassword,
      newPassword: payload.newPassword,
    );
    if (ok) _showMessage('Cap nhat mat khau thanh cong');
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFFFFAF0);
    const cardBg = Colors.white;
    const accent = Color(0xFFE67E22);

    final displayName = ((_profile?['name'] ?? '').toString().trim().isEmpty)
        ? 'Chua cap nhat ten'
        : (_profile?['name'] ?? '').toString();
    final displayPhone = ((_profile?['sdt'] ?? '').toString().trim().isEmpty)
        ? 'Chua cap nhat SDT'
        : (_profile?['sdt'] ?? '').toString();
    final displayAddress = ((_profile?['live'] ?? '').toString().trim().isEmpty)
        ? 'Chua cap nhat dia chi'
        : (_profile?['live'] ?? '').toString();

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        title: const Text('Tai khoan'),
        actions: [
          IconButton(
            onPressed: _loading || _saving ? null : _loadProfile,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: accent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFFFE4BF),
                        child: const Icon(Icons.person_rounded, color: accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayPhone,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayAddress,
                              style: const TextStyle(color: Colors.black45),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _ActionCard(
                  icon: Icons.edit_outlined,
                  title: 'Cap nhat ten',
                  subtitle: displayName,
                  onTap: _saving
                      ? () {}
                      : () {
                          _handleUpdateName();
                        },
                ),
                _ActionCard(
                  icon: Icons.phone_outlined,
                  title: 'Cap nhat so dien thoai',
                  subtitle: displayPhone,
                  onTap: _saving
                      ? () {}
                      : () {
                          _handleUpdatePhone();
                        },
                ),
                _ActionCard(
                  icon: Icons.location_on_outlined,
                  title: 'Cap nhat dia chi',
                  subtitle: displayAddress,
                  onTap: _saving
                      ? () {}
                      : () {
                          _handleUpdateAddress();
                        },
                ),
                _ActionCard(
                  icon: Icons.lock_outline_rounded,
                  title: 'Cap nhat mat khau',
                  subtitle: 'Doi mat khau dang nhap',
                  onTap: _saving
                      ? () {}
                      : () {
                          _handleUpdatePassword();
                        },
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Dang xuat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFFE67E22)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _PasswordPayload {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const _PasswordPayload({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });
}
