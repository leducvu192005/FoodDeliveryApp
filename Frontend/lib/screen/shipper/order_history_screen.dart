import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/order_model.dart';
import 'package:flutter_application_1/services/order_service.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({
    super.key,
    required this.orderService,
  });

  final OrderService orderService;

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<OrderModel>> _historyFuture;
  final TextEditingController _searchController = TextEditingController();

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchCompletedOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<OrderModel>> _fetchCompletedOrders({String search = ''}) async {
    try {
      return await widget.orderService.getCompletedOrders(search: search);
    } catch (error) {
      final message = error.toString();
      if (message.contains('Vui long dang nhap lai')) {
        if (mounted) {
          Future.microtask(() {
            if (!mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          });
        }
        return const <OrderModel>[];
      }
      rethrow;
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _historyFuture = _fetchCompletedOrders(search: _searchController.text);
    });
    try {
      await _historyFuture;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _loadHistory(),
              decoration: InputDecoration(
                hintText: 'Tìm theo nhà hàng, khách hàng, mã đơn...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _loadHistory,
                  icon: const Icon(Icons.tune),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<OrderModel>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Không tải được lịch sử đơn.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final orders = snapshot.data ?? const <OrderModel>[];
                if (orders.isEmpty) {
                  return const Center(
                    child: Text('Chưa có đơn hoàn thành.'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.restaurant?.name ?? 'Nhà hàng',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  'Khách: ${order.customer?.fullName ?? 'Khách hàng'}'),
                              Text(
                                'Thời gian: ${_dateFormat.format(order.completedAt?.toLocal() ?? DateTime.now())}',
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Giao toi: ${order.deliveryAddressDisplay}',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Thu nhập: ${_currency.format(order.earning)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
