import 'package:flutter/material.dart';
import '../../../services/order_services.dart';
import '../../../services/seller_services.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final OrderServices _orderServices = OrderServices();
  final SellerService _sellerService = SellerService();
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _orderServices.getSellerOrders();
  }

  void _reload() {
    setState(() {
      _ordersFuture = _orderServices.getSellerOrders();
    });
  }

  void _markDone(int orderId) async {
    try {
      await _sellerService.markOrderDone(orderId);
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Da danh dau lam xong!')),
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

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return '';
    final parsed = DateTime.tryParse(rawDate.toString());
    if (parsed == null) return rawDate.toString();
    final d = parsed.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đơn hàng',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.green[700],
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green[700],
            tabs: const [
              Tab(text: 'Dang xu ly'),
              Tab(text: 'Hoan thanh'),
            ],
          ),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.green));
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Lỗi: ${snapshot.error}',
                      style: const TextStyle(color: Colors.black54)));
            }

            final allOrders = snapshot.data ?? [];
            final preparing = allOrders.where((o) {
              final status = (o['status'] ?? '').toString().toLowerCase();
              return status != 'delivered' &&
                  status != 'cancelled' &&
                  status != 'done';
            }).toList();
            final done = allOrders.where((o) {
              final status = (o['status'] ?? '').toString().toLowerCase();
              return status == 'delivered' ||
                  status == 'cancelled' ||
                  status == 'done';
            }).toList();

            return TabBarView(
              children: [
                _OrderList(
                  orders: preparing,
                  emptyIcon: Icons.receipt_long_outlined,
                  emptyText: 'Chua co don hang dang xu ly',
                  formatDate: _formatDate,
                  onMarkDone: _markDone,
                ),
                _OrderList(
                  orders: done,
                  emptyIcon: Icons.check_circle_outline,
                  emptyText: 'Chua co don hang hoan thanh',
                  formatDate: _formatDate,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final IconData emptyIcon;
  final String emptyText;
  final String Function(dynamic) formatDate;
  final void Function(int)? onMarkDone;

  const _OrderList({
    required this.orders,
    required this.emptyIcon,
    required this.emptyText,
    required this.formatDate,
    this.onMarkDone,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(emptyText,
                style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (_, index) {
        final order = orders[index];
        final items = (order['items'] as List<dynamic>? ?? []);
        final total = (order['total_price'] as num?)?.toDouble() ?? 0;
        final status = order['status'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Đơn #${order['id']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    _StatusChip(status: status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(formatDate(order['created_at']),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const Divider(height: 16),
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('${item['quantity']}x ',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green)),
                          Expanded(
                              child: Text(item['dish_name'] ?? '',
                                  overflow: TextOverflow.ellipsis)),
                          Text(
                              '\$${((item['dish_price'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )),
                const Divider(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('Tổng: \$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green)),
                ),
                if (onMarkDone != null && status == 'pending') ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => onMarkDone!(order['id'] as int),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Da lam xong'),
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
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final String label;

    switch (status) {
      case 'pending':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        label = 'Cho xu ly';
        break;
      case 'confirmed':
      case 'ready_for_pickup':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        label = 'Cho shipper nhan';
        break;
      case 'accepted':
        bgColor = Colors.cyan.shade50;
        textColor = Colors.cyan.shade700;
        label = 'Shipper da nhan';
        break;
      case 'picked_up':
      case 'seller':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        label = 'Dang giao';
        break;
      case 'delivered':
      case 'done':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        label = 'Hoan thanh';
        break;
      case 'cancelled':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        label = 'Da huy';
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade600;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              color: textColor, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
