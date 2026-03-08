import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../models/order_model.dart';
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
    final status = (order['status'] ?? '').toString().toLowerCase();
    return status == 'delivered' || status == 'cancelled' || status == 'done';
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
              Tab(text: 'Đơn hàng của bạn'),
              Tab(text: 'Lich su'),
            ],
          ),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: accent));
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
            final ongoing =
                allOrders.where((o) => !_isHistoryOrder(o)).toList();
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

  String _statusLabel(String rawStatus) {
    switch (parseOrderStatus(rawStatus.toLowerCase())) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        return 'Cho duoc xu ly';
      case OrderStatus.accepted:
        return 'Dang lay hang';
      case OrderStatus.pickedUp:
        return 'Dang tren duong giao';
      case OrderStatus.delivered:
        return 'Hoan thanh don';
      case OrderStatus.cancelled:
        return 'Da huy';
    }
  }

  int _statusStep(String rawStatus) {
    switch (parseOrderStatus(rawStatus.toLowerCase())) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        return 0;
      case OrderStatus.accepted:
        return 1;
      case OrderStatus.pickedUp:
        return 2;
      case OrderStatus.delivered:
        return 3;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  String _paymentStatusLabel(String rawStatus) {
    switch (rawStatus.toLowerCase()) {
      case 'paid':
        return 'Da thanh toan';
      case 'pending':
        return 'Chua thanh toan';
      case 'failed':
        return 'Thanh toan that bai';
      default:
        return rawStatus;
    }
  }

  String _formatMoney(num amount) {
    final value = amount.toDouble();
    final text =
        value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
    return '\$$text';
  }

  int? _estimatedDeliveryMinutes(Map<String, dynamic> order) {
    final raw =
        order['estimated_delivery_minutes'] ?? order['estimated_minutes'];
    if (raw is int) return raw > 0 ? raw : null;
    if (raw is num) return raw.toInt() > 0 ? raw.toInt() : null;
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  String? _estimatedDeliveryText(Map<String, dynamic> order) {
    final minutes = _estimatedDeliveryMinutes(order);
    if (minutes == null) return null;

    final createdAt = DateTime.tryParse((order['created_at'] ?? '').toString());
    if (createdAt == null) {
      return '$minutes phut';
    }

    final eta = createdAt.toLocal().add(Duration(minutes: minutes));
    final time =
        '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';
    final date =
        '${eta.day.toString().padLeft(2, '0')}/${eta.month.toString().padLeft(2, '0')}/${eta.year}';
    return '$time $date';
  }

  String _resolveImageUrl(String rawUrl) {
    final value = rawUrl.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) {
      return '${ApiConfig.baseUrl}$value';
    }
    return '${ApiConfig.baseUrl}/$value';
  }

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
        final normalizedStatus = _statusLabel(status);
        final currentStep = _statusStep(status);
        final estimatedDeliveryText = _estimatedDeliveryText(order);

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
                  Text(
                    'Trang thai: $normalizedStatus | Thanh toan: ${_paymentStatusLabel(paymentStatus)}',
                  ),
                  const SizedBox(height: 10),
                  _OrderStatusTracker(
                    currentStep: currentStep,
                    accent: accent,
                  ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Mon trong don',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...items.map((item) {
                      final dishName =
                          (item['dish_name'] ?? 'Mon an').toString();
                      final dishImage = _resolveImageUrl(
                        (item['dish_image'] ?? '').toString(),
                      );
                      final quantity =
                          ((item['quantity'] as num?)?.toInt() ?? 0);
                      final dishPrice =
                          (item['dish_price'] as num?)?.toDouble() ?? 0;
                      final itemTotal = dishPrice * quantity;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _OrderItemTile(
                          dishName: dishName,
                          dishImage: dishImage,
                          quantity: quantity,
                          itemTotal: _formatMoney(itemTotal),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Tong tien don: ${_formatMoney(total)}',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (estimatedDeliveryText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Du kien giao den: $estimatedDeliveryText',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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

class _OrderStatusTracker extends StatelessWidget {
  const _OrderStatusTracker({
    required this.currentStep,
    required this.accent,
  });

  final int currentStep;
  final Color accent;

  static const List<String> _steps = <String>[
    'Cho duoc xu ly',
    'Dang lay hang',
    'Dang tren duong giao',
    'Hoan thanh don',
  ];

  @override
  Widget build(BuildContext context) {
    if (currentStep < 0) {
      return const Text(
        'Don hang da bi huy',
        style: TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(_steps.length * 2 - 1, (index) {
            if (index.isOdd) {
              final connectorIndex = index ~/ 2;
              final isActive = connectorIndex < currentStep;
              return Expanded(
                child: Container(
                  height: 3,
                  color: isActive ? accent : Colors.black12,
                ),
              );
            }

            final stepIndex = index ~/ 2;
            final isDone = stepIndex <= currentStep;
            return Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? accent : Colors.white,
                border: Border.all(
                  color: isDone ? accent : Colors.black26,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(
                      Icons.check,
                      size: 10,
                      color: Colors.white,
                    )
                  : null,
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _steps[currentStep],
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({
    required this.dishName,
    required this.dishImage,
    required this.quantity,
    required this.itemTotal,
  });

  final String dishName;
  final String dishImage;
  final int quantity;
  final String itemTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: dishImage.isNotEmpty
              ? Image.network(
                  dishImage,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _OrderItemImageFallback(),
                )
              : const _OrderItemImageFallback(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dishName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'So luong: $quantity',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          itemTotal,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _OrderItemImageFallback extends StatelessWidget {
  const _OrderItemImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      color: const Color(0xFFF4F1EA),
      alignment: Alignment.center,
      child: const Icon(
        Icons.fastfood_rounded,
        color: Color(0xFFE67E22),
        size: 24,
      ),
    );
  }
}
