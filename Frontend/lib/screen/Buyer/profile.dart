import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/auth_services.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'form_seller.dart';
import 'form_shipper.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  static const Duration _requestTimeout = Duration(seconds: 15);

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
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.path('/profile/me')),
            headers: await _authHeaders(),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        _profile =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else {
        _profile = null;
      }
    } on TimeoutException {
      _profile = null;
      _showMessage('Ket noi qua lau. Vui long thu lai.');
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
      final response = await http
          .put(
            Uri.parse(ApiConfig.path('/profile/me')),
            headers: await _authHeaders(),
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);

      if (!mounted) return false;

      if (response.statusCode == 200) {
        await _loadProfile();
        return true;
      }

      _showMessage('Khong the cap nhat: ${utf8.decode(response.bodyBytes)}');
      return false;
    } on TimeoutException {
      _showMessage('Luu thong tin qua lau. Vui long thu lai.');
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
      final response = await http
          .put(
            Uri.parse(ApiConfig.path('/profile/me/password')),
            headers: await _authHeaders(),
            body: jsonEncode({
              'current_password': currentPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(_requestTimeout);

      if (!mounted) return false;

      if (response.statusCode == 200) {
        return true;
      }

      _showMessage(
          'Khong the cap nhat mat khau: ${utf8.decode(response.bodyBytes)}');
      return false;
    } on TimeoutException {
      _showMessage('Luu mat khau qua lau. Vui long thu lai.');
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

  Future<void> _openEditProfileScreen() async {
    final profile = _profile;
    if (profile == null || _saving) return;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BuyerEditProfileScreen(
          initialName: (profile['name'] ?? '').toString(),
          initialPhone: (profile['sdt'] ?? '').toString(),
          initialAddress: (profile['live'] ?? '').toString(),
          onSave: ({
            required String name,
            required String phone,
            required String address,
          }) async {
            return _updateProfileField({
              'name': name,
              'sdt': phone,
              'live': address,
            });
          },
        ),
      ),
    );

    if (saved == true) {
      _showMessage('Cap nhat thong tin ca nhan thanh cong');
    }
  }

  Future<void> _openChangePasswordScreen() async {
    if (_saving) return;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BuyerChangePasswordScreen(
          onSave: ({
            required String currentPassword,
            required String newPassword,
          }) async {
            return _updatePassword(
              currentPassword: currentPassword,
              newPassword: newPassword,
            );
          },
        ),
      ),
    );

    if (saved == true) {
      _showMessage('Cap nhat mat khau thanh cong');
    }
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
        backgroundColor: accent,
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
                  title: 'Sua thong tin ca nhan',
                  subtitle: 'Cap nhat ten, so dien thoai, dia chi',
                  onTap: _saving
                      ? () {}
                      : () {
                          _openEditProfileScreen();
                        },
                ),
                _ActionCard(
                  icon: Icons.lock_outline_rounded,
                  title: 'Cap nhat mat khau',
                  subtitle: 'Doi mat khau dang nhap',
                  onTap: _saving
                      ? () {}
                      : () {
                          _openChangePasswordScreen();
                        },
                ),
                const SizedBox(height: 20),
                _ActionCard(
                  icon: Icons.store_rounded,
                  title: 'Tro thanh Seller',
                  subtitle: 'Dang ky ban hang tren ung dung',
                  onTap: _saving
                      ? () {}
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FormSeller(),
                            ),
                          );
                        },
                ),
                _ActionCard(
                  icon: Icons.delivery_dining_outlined,
                  title: 'Tro thanh Shipper',
                  subtitle: 'Dang ky giao hang tren ung dung',
                  onTap: _saving
                      ? () {}
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FormShipper(),
                            ),
                          );
                        },
                ),
                const SizedBox(height: 10),
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
