import 'package:flutter/material.dart';
import '../../../services/seller_services.dart';
import '../menu/menu.dart';
import '../order/order.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  final SellerService _sellerService = SellerService();
  bool _isOpen = false;
  String _shopName = 'Kitty Food';
  double _totalRevenue = 0;
  double _todayRevenue = 0;
  int _todayOrders = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final statusData = await _sellerService.getStatus();
      final revenueData = await _sellerService.getRevenue();
      if (mounted) {
        setState(() {
          _isOpen = statusData['status'] == 'on';
          _shopName = statusData['name'] ?? 'Kitty Food';
          _totalRevenue =
              (revenueData['total_revenue'] as num?)?.toDouble() ?? 0;
          _todayRevenue =
              (revenueData['today_revenue'] as num?)?.toDouble() ?? 0;
          _todayOrders = (revenueData['today_orders'] as num?)?.toInt() ?? 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loi tai du lieu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleStatus() async {
    final newStatus = _isOpen ? 'off' : 'on';
    try {
      await _sellerService.toggleStatus(newStatus);
      setState(() => _isOpen = !_isOpen);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loi: $e')),
        );
      }
    }
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _shopName,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Row(
            children: [
              Text(
                _isOpen ? 'Mo' : 'Dong',
                style: TextStyle(
                  color: _isOpen ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Switch(
                value: _isOpen,
                onChanged: (_) => _toggleStatus(),
                activeColor: Colors.green,
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hieu suat ban hang',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatusCard(
                        _isOpen ? 'Dang hoat dong' : 'Ngung hoat dong',
                        '$_todayOrders',
                        'Don hom nay',
                        _isOpen ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      _buildIncomeCard(
                        'Thu nhap hom nay',
                        _formatMoney(_todayRevenue),
                        '$_todayOrders don hang',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tong doanh thu',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'd ${_formatMoney(_totalRevenue)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 20,
                    children: [
                      _buildMenuIcon(context, Icons.receipt_long, 'Don hang',
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const OrderScreen()),
                        ).then((_) => _loadData());
                      }),
                      _buildMenuIcon(context, Icons.menu_book, 'Thuc don', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MenuScreen()),
                        );
                      }),
                      _buildMenuIcon(
                          context, Icons.people_outline, 'GFin', null),
                      _buildMenuIcon(
                          context, Icons.comment_outlined, 'Phan hoi', null),
                      _buildMenuIcon(context, Icons.storefront, 'Quan', null),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(String title, String value, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 4, backgroundColor: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(sub,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeCard(String title, String amount, String orders) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 16),
            Text('d $amount',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(orders,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuIcon(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: Icon(icon, color: Colors.grey[700], size: 28),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
