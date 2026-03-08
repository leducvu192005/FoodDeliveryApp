import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/order_model.dart';
import 'package:flutter_application_1/screen/shipper/edit_profile_screen.dart';
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
  bool _redirectingToLogin = false;

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
    } catch (error, _) {
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

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _redirectToLoginIfNeeded() {
    if (!mounted || _redirectingToLogin) return;
    _redirectingToLogin = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    });
  }

  Future<void> _openEditProfileScreen(ShipperProfileModel profile) async {
    final updatedProfile =
        await Navigator.of(context).push<ShipperProfileModel>(
      MaterialPageRoute(
        builder: (_) => EditShipperProfileScreen(
          orderService: widget.orderService,
          initialProfile: profile,
        ),
      ),
    );
    if (!mounted || updatedProfile == null) return;
    setState(() {
      _profileFuture = Future<ShipperProfileModel>.value(updatedProfile);
    });
    _showSnack('Cap nhat thong tin ca nhan thanh cong');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ca nhan',
        ),
        backgroundColor: Colors.deepOrange,
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
              _redirectToLoginIfNeeded();
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
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFFFE4BF),
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.orange.shade800,
                          ),
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
                  subtitle: 'Nhan vao de mo man hinh chinh sua thong tin',
                  onTap: _saving ? null : () => _openEditProfileScreen(profile),
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
