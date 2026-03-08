import 'package:flutter/material.dart';

typedef BuyerProfileSaveCallback = Future<bool> Function({
  required String name,
  required String phone,
  required String address,
});

class BuyerEditProfileScreen extends StatefulWidget {
  const BuyerEditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialPhone,
    required this.initialAddress,
    required this.onSave,
  });

  final String initialName;
  final String initialPhone;
  final String initialAddress;
  final BuyerProfileSaveCallback onSave;

  @override
  State<BuyerEditProfileScreen> createState() => _BuyerEditProfileScreenState();
}

class _BuyerEditProfileScreenState extends State<BuyerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _addressController = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
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
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
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
      appBar: AppBar(title: const Text('Sua thong tin ca nhan')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Ten',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Ten khong duoc de trong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'So dien thoai',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'So dien thoai khong duoc de trong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Dia chi giao hang',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
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
                label: Text(_saving ? 'Dang luu...' : 'Luu thay doi'),
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
