import 'package:flutter/material.dart';
import '../../../services/admin_services.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String _filterRole = 'all';

  static const _roles = ['all', 'buyer', 'seller', 'shipper', 'admin'];
  static const _roleLabels = {
    'all': 'Tat ca',
    'buyer': 'Nguoi mua',
    'seller': 'Nguoi ban',
    'shipper': 'Shipper',
    'admin': 'Admin',
  };

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final users = await AdminServices.getUsers();
      if (mounted) setState(() => _users = users);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_filterRole == 'all') return _users;
    return _users.where((u) => u['role'] == _filterRole).toList();
  }

  Future<void> _toggleUserActive(int userId, int globalIndex) async {
    try {
      final result = await AdminServices.toggleUserActive(userId);
      if (mounted) {
        setState(() {
          _users[globalIndex]['is_active'] = result['is_active'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loi: $e')),
        );
      }
    }
  }

  Future<void> _changeUserRole(int userId, int globalIndex) async {
    final currentRole = _users[globalIndex]['role'] ?? 'buyer';
    final availableRoles = ['buyer', 'seller', 'shipper', 'admin']
        .where((r) => r != currentRole)
        .toList();

    final newRole = await showDialog<String>(
      context: context,
      builder: (context) => _RolePickerDialog(
        currentRole: currentRole,
        availableRoles: availableRoles,
        userName: _users[globalIndex]['full_name'] ?? '',
      ),
    );

    if (newRole == null || !mounted) return;

    try {
      final result = await AdminServices.changeUserRole(userId, newRole);
      if (mounted) {
        setState(() {
          _users[globalIndex]['role'] = result['new_role'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Da doi role thanh ${result['new_role']}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loi: $e')),
        );
      }
    }
  }

  int _globalIndex(Map<String, dynamic> user) {
    return _users.indexWhere((u) => u['id'] == user['id']);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE67E22);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filteredUsers;

    return Column(
      children: [
        // Review buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const _PendingUserReviewScreen(type: 'seller'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.store_outlined, size: 18),
                  label: const Text('Duyet Seller'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const _PendingUserReviewScreen(type: 'shipper'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.delivery_dining_outlined, size: 18),
                  label: const Text('Duyet Shipper'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Filter chips
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _roles.map((role) {
                final isSelected = _filterRole == role;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_roleLabels[role] ?? role),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _filterRole = role),
                    selectedColor: accent.withAlpha(40),
                    checkmarkColor: accent,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // User count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${filtered.length} nguoi dung',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
        ),
        // User list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadUsers,
            child: filtered.isEmpty
                ? const Center(child: Text('Khong co nguoi dung'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      final gi = _globalIndex(user);
                      return _UserCard(
                        user: user,
                        accent: accent,
                        onToggleActive: () =>
                            _toggleUserActive(user['id'] as int, gi),
                        onChangeRole: () =>
                            _changeUserRole(user['id'] as int, gi),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

// ==================== User Card ====================
class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final Color accent;
  final VoidCallback onToggleActive;
  final VoidCallback onChangeRole;

  const _UserCard({
    required this.user,
    required this.accent,
    required this.onToggleActive,
    required this.onChangeRole,
  });

  @override
  Widget build(BuildContext context) {
    final role = user['role'] ?? '';
    final isActive = user['is_active'] == true;
    final isAdmin = role == 'admin';

    final roleColor = _roleColor(role);
    final roleIcon = _roleIcon(role);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: roleColor.withAlpha(30),
                  child: Icon(roleIcon, color: roleColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['full_name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${user['email']}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${user['sdt'] ?? ''}',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: roleColor.withAlpha(80)),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                // Toggle active
                if (!isAdmin) ...[
                  Icon(
                    isActive ? Icons.check_circle : Icons.block,
                    size: 16,
                    color: isActive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isActive ? 'Hoat dong' : 'Bi khoa',
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 28,
                    child: Switch(
                      value: isActive,
                      activeColor: accent,
                      onChanged: (_) => onToggleActive(),
                    ),
                  ),
                ],
                const Spacer(),
                // Change role button
                if (!isAdmin)
                  SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: onChangeRole,
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: const Text(
                        'Doi role',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(color: accent.withAlpha(120)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (isAdmin)
                  const Chip(
                    label: Text('Admin', style: TextStyle(fontSize: 11)),
                    backgroundColor: Color(0xFFFFE0B2),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'seller':
        return Colors.green;
      case 'shipper':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  static IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'seller':
        return Icons.store;
      case 'shipper':
        return Icons.delivery_dining;
      default:
        return Icons.person;
    }
  }
}

// ==================== Pending User Review Screen ====================
class _PendingUserReviewScreen extends StatefulWidget {
  final String type; // 'seller' or 'shipper'
  const _PendingUserReviewScreen({required this.type});

  @override
  State<_PendingUserReviewScreen> createState() =>
      _PendingUserReviewScreenState();
}

class _PendingUserReviewScreenState extends State<_PendingUserReviewScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingUsers();
  }

  Future<void> _loadPendingUsers() async {
    setState(() => _loading = true);
    try {
      final users = await AdminServices.getPendingUsers(widget.type);
      if (mounted) setState(() => _users = users);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review(int userId, String status) async {
    try {
      await AdminServices.reviewPendingUser(userId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'yes' ? 'Da duyet thanh cong' : 'Da tu choi',
            ),
            backgroundColor: status == 'yes' ? Colors.green : Colors.red,
          ),
        );
        _loadPendingUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSeller = widget.type == 'seller';
    final accent = isSeller ? const Color(0xFFE67E22) : Colors.purple;
    final title = isSeller ? 'Duyet ho so Seller' : 'Duyet ho so Shipper';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('Khong co ho so nao'))
              : RefreshIndicator(
                  onRefresh: _loadPendingUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return _PendingUserCard(
                        user: user,
                        type: widget.type,
                        onApprove: () => _review(user['id'] as int, 'yes'),
                        onReject: () => _review(user['id'] as int, 'no'),
                      );
                    },
                  ),
                ),
    );
  }
}

class _PendingUserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String type;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingUserCard({
    required this.user,
    required this.type,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isSeller = type == 'seller';
    final headerIcon = isSeller ? Icons.store : Icons.delivery_dining;
    final headerColor = isSeller ? const Color(0xFFE67E22) : Colors.purple;
    final headerText = isSeller
        ? (user['name_shop'] ?? 'Seller')
        : (user['full_name'] ?? 'Shipper');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(headerIcon, color: headerColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    headerText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withAlpha(80)),
                  ),
                  child: const Text(
                    'Cho duyet',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.person_outline, 'Ho ten', user['full_name'] ?? ''),
            _infoRow(Icons.email_outlined, 'Email', user['email'] ?? ''),
            _infoRow(Icons.phone_outlined, 'SDT', user['sdt'] ?? ''),
            _infoRow(Icons.badge_outlined, 'CCCD', user['cccd'] ?? ''),
            if (isSeller) ...[
              _infoRow(Icons.storefront_outlined, 'Ten quan',
                  user['name_shop'] ?? ''),
              _infoRow(Icons.location_on_outlined, 'Dia chi',
                  user['address_shop'] ?? ''),
            ],
            if (!isSeller) ...[
              _infoRow(Icons.directions_car_outlined, 'Dang ky xe',
                  user['vehicle_registration'] ?? ''),
              _infoRow(Icons.credit_card_outlined, 'Bang lai',
                  user['license'] ?? ''),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Tu choi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Duyet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black45),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Role Picker Dialog ====================
class _RolePickerDialog extends StatelessWidget {
  final String currentRole;
  final List<String> availableRoles;
  final String userName;

  const _RolePickerDialog({
    required this.currentRole,
    required this.availableRoles,
    required this.userName,
  });

  static const _roleInfo = {
    'buyer': {'label': 'Nguoi mua', 'icon': Icons.person, 'color': Colors.blue},
    'seller': {
      'label': 'Nguoi ban',
      'icon': Icons.store,
      'color': Colors.green
    },
    'shipper': {
      'label': 'Shipper',
      'icon': Icons.delivery_dining,
      'color': Colors.purple
    },
    'admin': {
      'label': 'Admin',
      'icon': Icons.admin_panel_settings,
      'color': Colors.red
    },
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Doi role nguoi dung',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Role hien tai: $currentRole',
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chon role moi:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...availableRoles.map((role) {
            final info = _roleInfo[role]!;
            final color = info['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: color.withAlpha(60)),
                ),
                leading: Icon(info['icon'] as IconData, color: color),
                title: Text(
                  info['label'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                onTap: () => Navigator.pop(context, role),
              ),
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huy'),
        ),
      ],
    );
  }
}
