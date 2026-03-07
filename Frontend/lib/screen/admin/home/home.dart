import 'package:flutter/material.dart';
import '../../../services/admin_services.dart';
import '../../../services/auth_services.dart';
import 'user.dart';
import 'order.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  Map<String, dynamic>? _stats;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final stats = await AdminServices.getStats();
      if (mounted) setState(() => _stats = stats);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE67E22);

    final pages = [
      _buildDashboardTab(accent),
      const AdminUserScreen(),
      const AdminOrderScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: accent,
        unselectedItemColor: Colors.black45,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tong quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Nguoi dung',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Don hang',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(Color accent) {
    if (_loadingStats) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_stats == null) {
      return const Center(child: Text('Khong co du lieu'));
    }

    final s = _stats!;
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Thong ke nguoi dung',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                label: 'Tong nguoi dung',
                value: '${s['total_users']}',
                icon: Icons.people,
                color: accent,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Nguoi mua',
                value: '${s['total_buyers']}',
                icon: Icons.shopping_bag,
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                label: 'Nguoi ban',
                value: '${s['total_sellers']}',
                icon: Icons.store,
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Shipper',
                value: '${s['total_shippers']}',
                icon: Icons.delivery_dining,
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Thong ke don hang',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                label: 'Tong don hang',
                value: '${s['total_orders']}',
                icon: Icons.receipt_long,
                color: Colors.teal,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Dang cho',
                value: '${s['pending_orders']}',
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                label: 'Hoan thanh',
                value: '${s['done_orders']}',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Mon an',
                value: '${s['total_dishes']}',
                icon: Icons.restaurant_menu,
                color: Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withAlpha(180)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tong doanh thu',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${(s['total_revenue'] as num).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
