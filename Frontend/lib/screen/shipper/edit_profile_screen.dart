import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/order_model.dart';
import 'package:flutter_application_1/services/order_service.dart';

class EditShipperProfileScreen extends StatefulWidget {
  const EditShipperProfileScreen({
    super.key,
    required this.orderService,
    required this.initialProfile,
  });

  final OrderService orderService;
  final ShipperProfileModel initialProfile;

  @override
  State<EditShipperProfileScreen> createState() =>
      _EditShipperProfileScreenState();
}

class _EditShipperProfileScreenState extends State<EditShipperProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialProfile.fullName,
    );
    _phoneController = TextEditingController(
      text: widget.initialProfile.phone,
    );
    _addressController = TextEditingController(
      text: widget.initialProfile.address,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate() || _saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final updatedProfile = await widget.orderService.updateShipperProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(updatedProfile);
    } catch (error, _) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
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
      appBar: AppBar(
        title: const Text('Sua thong tin ca nhan'),
      ),
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
                  labelText: 'Ho va ten',
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
                keyboardType: TextInputType.streetAddress,
                textInputAction: TextInputAction.done,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Dia chi',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
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
