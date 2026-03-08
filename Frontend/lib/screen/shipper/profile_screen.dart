import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/order_model.dart';
import 'package:flutter_application_1/services/order_service.dart';
import 'package:flutter_application_1/widgets/stat_card.dart';
import '../../services/auth_services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.orderService,
  });

  final OrderService orderService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<ShipperProfileModel> _profileFuture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.orderService.getShipperProfile();
  }

  Future<void> _reload() async {
    setState(() {
      _profileFuture = widget.orderService.getShipperProfile();
    });
    try {
      await _profileFuture;
    } catch (error) {
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _logout() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      await widget.orderService.setShipperOnline(isOnline: false);
    } catch (_) {}

    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
        content: TextField(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Huy'),
          ),
          FilledButton(
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

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveProfile({
    required String successMessage,
    required Future<ShipperProfileModel> Function() action,
  }) async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final updatedProfile = await action();
      if (!mounted) return;
      setState(() {
        _profileFuture = Future<ShipperProfileModel>.value(updatedProfile);
      });
      _showSnack(successMessage);
    } catch (error) {
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _editName(ShipperProfileModel profile) async {
    final value = await _showEditFieldDialog(
      title: 'Cap nhat ten',
      label: 'Ho va ten',
      initialValue: profile.fullName,
      icon: Icons.person_outline_rounded,
    );
    if (value == null) return;
    if (value.isEmpty) {
      _showSnack('Ten khong duoc de trong');
      return;
    }

    await _saveProfile(
      successMessage: 'Cap nhat ten thanh cong',
      action: () => widget.orderService.updateShipperProfile(fullName: value),
    );
  }

  Future<void> _editPhone(ShipperProfileModel profile) async {
    final value = await _showEditFieldDialog(
      title: 'Cap nhat so dien thoai',
      label: 'So dien thoai',
      initialValue: profile.phone,
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
    );
    if (value == null) return;
    if (value.isEmpty) {
      _showSnack('So dien thoai khong duoc de trong');
      return;
    }

    await _saveProfile(
      successMessage: 'Cap nhat so dien thoai thanh cong',
      action: () => widget.orderService.updateShipperProfile(phone: value),
    );
  }

  Future<void> _editAddress(ShipperProfileModel profile) async {
    final value = await _showEditFieldDialog(
      title: 'Cap nhat dia chi',
      label: 'Dia chi',
      initialValue: profile.address,
      icon: Icons.location_on_outlined,
      maxLines: 2,
    );
    if (value == null) return;

    await _saveProfile(
      successMessage: 'Cap nhat dia chi thanh cong',
      action: () => widget.orderService.updateShipperProfile(address: value),
    );
  }

  Future<void> _showEditProfileBottomSheet(ShipperProfileModel profile) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetActionTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Sua ten',
                  subtitle: profile.fullName.trim().isEmpty
                      ? 'Chua cap nhat ten'
                      : profile.fullName,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _editName(profile);
                  },
                ),
                _SheetActionTile(
                  icon: Icons.phone_outlined,
                  title: 'Sua so dien thoai',
                  subtitle: profile.phone.trim().isEmpty
                      ? 'Chua cap nhat so dien thoai'
                      : profile.phone,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _editPhone(profile);
                  },
                ),
                _SheetActionTile(
                  icon: Icons.location_on_outlined,
                  title: 'Sua dia chi',
                  subtitle: profile.address.trim().isEmpty
                      ? 'Chua cap nhat dia chi'
                      : profile.address,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _editAddress(profile);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ca nhan'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<ShipperProfileModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            if (snapshot.error.toString().contains("Vui long dang nhap lai")) {
              Future.microtask(() {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              });
            }

            return const Center(child: Text("Session expired"));
          }

          final profile = snapshot.data!;
          final displayName = profile.fullName.trim().isEmpty
              ? 'Chua cap nhat ten'
              : profile.fullName;
          final displayPhone = profile.phone.trim().isEmpty
              ? 'Chua cap nhat so dien thoai'
              : profile.phone;
          final displayAddress = profile.address.trim().isEmpty
              ? 'Chua cap nhat dia chi'
              : profile.address;

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Rating: ${profile.rating.toStringAsFixed(1)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.55,
                  children: [
                    StatCard(
                      title: 'So don hoan thanh',
                      value: '${profile.completedOrders}',
                      icon: Icons.task_alt_outlined,
                    ),
                    StatCard(
                      title: 'Ty le hoan thanh',
                      value: '${profile.completionRate.toStringAsFixed(1)}%',
                      icon: Icons.percent_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _EditableInfoCard(
                  icon: Icons.badge_outlined,
                  title: 'Thong tin ca nhan',
                  subtitle: 'Nhan vao de sua ten, so dien thoai, dia chi',
                  onTap: _saving
                      ? null
                      : () => _showEditProfileBottomSheet(profile),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thong tin lien he',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(label: 'Email', value: profile.email),
                        _InfoRow(label: 'So dien thoai', value: displayPhone),
                        _InfoRow(label: 'Dia chi', value: displayAddress),
                      ],
                    ),
                  ),
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
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Chua cap nhat' : value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableInfoCard extends StatelessWidget {
  const _EditableInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _SheetActionTile extends StatelessWidget {
  const _SheetActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.edit_outlined),
        ),
      ),
    );
  }
}
