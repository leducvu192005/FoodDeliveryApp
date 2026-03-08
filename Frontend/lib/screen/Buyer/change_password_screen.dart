import 'package:flutter/material.dart';

typedef BuyerPasswordSaveCallback = Future<bool> Function({
  required String currentPassword,
  required String newPassword,
});

class BuyerChangePasswordScreen extends StatefulWidget {
  const BuyerChangePasswordScreen({
    super.key,
    required this.onSave,
  });

  final BuyerPasswordSaveCallback onSave;

  @override
  State<BuyerChangePasswordScreen> createState() =>
      _BuyerChangePasswordScreenState();
}

class _BuyerChangePasswordScreenState extends State<BuyerChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _saving = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate() || _saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final ok = await widget.onSave(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );
      if (!mounted || !ok) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cap nhat mat khau')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _currentPasswordController,
                obscureText: !_showCurrentPassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Mat khau hien tai',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _showCurrentPassword = !_showCurrentPassword;
                      });
                    },
                    icon: Icon(
                      _showCurrentPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Vui long nhap mat khau hien tai';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_showNewPassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Mat khau moi',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _showNewPassword = !_showNewPassword;
                      });
                    },
                    icon: Icon(
                      _showNewPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Vui long nhap mat khau moi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Nhap lai mat khau moi',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.verified_user_outlined),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _showConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Vui long nhap lai mat khau moi';
                  }
                  if (value!.trim() != _newPasswordController.text.trim()) {
                    return 'Mat khau moi khong khop';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Dang luu...' : 'Luu mat khau'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
