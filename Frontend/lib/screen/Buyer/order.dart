import 'package:flutter/material.dart';

import '../../services/order_services.dart';

class Order extends StatefulWidget {
  const Order({super.key});

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  final OrderServices _orderServices = OrderServices();
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _orderServices.getOrders();
  }

  void _reload() {
    setState(() {
      _ordersFuture = _orderServices.getOrders();
    });
  }

  bool _isHistoryOrder(Map<String, dynamic> order) {
    final paymentStatus = (order['payment_status'] ?? '').toString().toLowerCase();
    final status = (order['status'] ?? '').toString().toLowerCase();
    return paymentStatus == 'paid' || status == 'completed' || status == 'cancelled';
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return 'Khong ro thoi gian';
    final parsed = DateTime.tryParse(rawDate.toString());
    if (parsed == null) return rawDate.toString();
    final d = parsed.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFFFFAF0);
    const cardBg = Colors.white;
    const accent = Color(0xFFE67E22);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          title: const Text('Don hang'),
          backgroundColor: pageBg,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: accent,
            labelColor: Colors.black87,
            tabs: [
              Tab(text: 'Dang xu ly'),
              Tab(text: 'Lich su'),
            ],
          ),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: accent));
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Khong tai duoc don hang: ${snapshot.error}',
                  style: const TextStyle(color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final allOrders = snapshot.data ?? [];
            final ongoing = allOrders.where((o) => !_isHistoryOrder(o)).toList();
            final history = allOrders.where(_isHistoryOrder).toList();

            return TabBarView(
              children: [
                _OrderList(
                  orders: ongoing,
                  emptyText: 'Ban chua co don dang xu ly',
                  cardBg: cardBg,
                  accent: accent,
                  formatDate: _formatDate,
                ),
                _OrderList(
                  orders: history,
                  emptyText: 'Chua co lich su don hang',
                  cardBg: cardBg,
                  accent: accent,
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
  final String emptyText;
  final Color cardBg;
  final Color accent;
  final String Function(dynamic) formatDate;

  const _OrderList({
    required this.orders,
    required this.emptyText,
    required this.cardBg,
    required this.accent,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (_, index) {
        final order = orders[index];
        final items = (order['items'] as List<dynamic>? ?? []);
        final itemCount = items.fold<int>(
          0,
          (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
        );
        final total = (order['total_price'] as num?)?.toDouble() ?? 0;
        final status = (order['status'] ?? 'pending').toString();
        final paymentStatus = (order['payment_status'] ?? 'pending').toString();
        final deliveryAddress = (order['delivery_address'] ?? '').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            title: Text(
              'Don #${order['id']}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$itemCount mon - ${formatDate(order['created_at'])}'),
                  const SizedBox(height: 4),
                  Text('Trang thai: $status | Thanh toan: $paymentStatus'),
                  if (deliveryAddress.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Dia chi giao: $deliveryAddress'),
                  ],
                ],
              ),
            ),
            trailing: Text(
              '\$${total.toStringAsFixed(2)}',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      },
    );
  }
}
