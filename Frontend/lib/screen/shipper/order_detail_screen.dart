import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/order_model.dart';
import 'package:flutter_application_1/services/order_service.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.orderService,
  });

  final String orderId;
  final OrderService orderService;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<OrderModel> _orderFuture;
  bool _processing = false;

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _orderFuture = widget.orderService.getOrderDetail(widget.orderId);
  }

  Future<void> _reload() async {
    setState(() {
      _orderFuture = widget.orderService.getOrderDetail(widget.orderId);
    });
    await _orderFuture;
  }

  Future<void> _markDelivering() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      await widget.orderService.markOrderDelivering(
        orderId: widget.orderId,
      );
      await _reload();
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _markCompleted() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      await widget.orderService.markOrderCompleted(
        orderId: widget.orderId,
      );
      await _reload();
      if (mounted) {
        _showSnack('Đơn hàng đã hoàn thành.');
      }
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn'),
      ),
      body: FutureBuilder<OrderModel>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Không tải được chi tiết đơn.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final order = snapshot.data!;
          final canMarkPicked = order.status == OrderStatus.pickedUp;
          final canMarkCompleted = order.status == OrderStatus.delivering;

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
                          'Thu nhập đơn: ${_currency.format(order.earning)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 14,
                          runSpacing: 10,
                          children: [
                            Text(
                                'Khoảng cách: ${order.distanceKm.toStringAsFixed(1)} km'),
                            Text('Dự kiến: ${order.estimatedMinutes} phút'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông tin nhà hàng',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(order.restaurant?.name ?? 'Nhà hàng'),
                        Text(order.restaurant?.address ?? 'Chưa có địa chỉ'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông tin khách hàng',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(order.customer?.fullName ?? 'Khách hàng'),
                        Text(
                          'Dia chi giao: ${order.deliveryAddressDisplay}',
                        ),
                        Text('SDT: ${order.customer?.phone ?? order.customerPhone}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Danh sách món',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (order.items.isEmpty)
                          const Text('Chưa có dữ liệu món ăn.')
                        else
                          ...order.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                        '${item.quantity} x ${item.itemName}'),
                                  ),
                                  Text(_currency.format(item.totalPrice)),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showSnack('Mở bản đồ chỉ đường.'),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Chỉ đường'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showSnack(
                            'Gọi ${order.customer?.phone ?? order.customerPhone}'),
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Gọi khách'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed:
                      canMarkPicked && !_processing ? _markDelivering : null,
                  child: const Text('Đã lấy hàng'),
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed:
                      canMarkCompleted && !_processing ? _markCompleted : null,
                  child: const Text('Đã giao hàng'),
                ),
                if (order.status == OrderStatus.completed) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Đơn đã hoàn thành lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(order.completedAt?.toLocal() ?? DateTime.now())}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
