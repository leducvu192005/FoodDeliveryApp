import 'package:flutter/material.dart';
import '../../../services/admin_services.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String _filterStatus = 'all';

  static const _statuses = ['all', 'pending', 'shipper', 'seller', 'done'];
  static const _statusLabels = {
    'all': 'Tat ca',
    'pending': 'Cho xu ly',
    'shipper': 'Cho shipper',
    'seller': 'Dang chuan bi',
    'done': 'Hoan thanh',
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final orders = await AdminServices.getOrders();
      if (mounted) setState(() => _orders = orders);
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

  List<Map<String, dynamic>> get _filteredOrders {
    if (_filterStatus == 'all') return _orders;
    return _orders.where((o) => o['status'] == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE67E22);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filteredOrders;

    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statuses.map((status) {
                final isSelected = _filterStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_statusLabels[status] ?? status),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _filterStatus = status),
                    selectedColor: accent.withAlpha(40),
                    checkmarkColor: accent,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Order count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${filtered.length} don hang',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
        ),
        // Order list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadOrders,
            child: filtered.isEmpty
                ? const Center(child: Text('Khong co don hang'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      return _OrderCard(order: order);
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? '';
    final statusInfo = _statusInfo(status);
    final statusColor = statusInfo['color'] as Color;
    final statusLabel = statusInfo['label'] as String;
    final statusIcon = statusInfo['icon'] as IconData;

    final totalPrice = (order['total_price'] as num?)?.toDouble() ?? 0;
    final deliveryFee = (order['delivery_fee'] as num?)?.toDouble() ?? 0;
    final grandTotal = totalPrice + deliveryFee;
    final method = order['payment_method'] ?? '?';
    final createdAt = order['created_at'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: statusColor.withAlpha(30),
                  child: Text(
                    '#${order['id']}',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Mon: \$${totalPrice.toStringAsFixed(2)} + Ship: \$${deliveryFee.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Info row
            Row(
              children: [
                Icon(
                  method == 'cod' ? Icons.payments_outlined : Icons.qr_code,
                  size: 14,
                  color: Colors.black45,
                ),
                const SizedBox(width: 4),
                Text(
                  method == 'cod'
                      ? 'Tien mat'
                      : method == 'sepay'
                          ? 'Chuyen khoan'
                          : method,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const Spacer(),
                const Icon(Icons.access_time, size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Map<String, dynamic> _statusInfo(String status) {
    switch (status) {
      case 'pending':
        return {
          'color': Colors.orange,
          'label': 'Cho xu ly',
          'icon': Icons.pending_actions,
        };
      case 'shipper':
        return {
          'color': Colors.blue,
          'label': 'Cho shipper',
          'icon': Icons.delivery_dining,
        };
      case 'seller':
        return {
          'color': Colors.purple,
          'label': 'Dang chuan bi',
          'icon': Icons.restaurant,
        };
      case 'done':
        return {
          'color': Colors.green,
          'label': 'Hoan thanh',
          'icon': Icons.check_circle,
        };
      default:
        return {
          'color': Colors.grey,
          'label': status,
          'icon': Icons.help_outline,
        };
    }
  }

  static String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}
