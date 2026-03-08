import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/order_model.dart';
import 'package:flutter_application_1/services/order_service.dart';
import 'package:flutter_application_1/widgets/stat_card.dart';
import 'package:intl/intl.dart';

import 'order_detail_screen.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({
    super.key,
    required this.orderService,
    this.refreshTick = 0,
  });

  final OrderService orderService;
  final int? refreshTick;

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  late Future<_EarningsViewData> _earningsFuture;

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'd',
    decimalDigits: 0,
  );
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _earningsFuture = _loadEarningsData();
  }

  @override
  void didUpdateWidget(covariant EarningsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.refreshTick ?? 0) != (oldWidget.refreshTick ?? 0)) {
      _reload();
    }
  }

  Future<_EarningsViewData> _loadEarningsData() async {
    final results = await Future.wait<dynamic>([
      widget.orderService.getEarningsSummary(),
      widget.orderService.getCompletedOrders(),
    ]);

    final summary = results[0] as EarningsSummary;
    final completedOrders = results[1] as List<OrderModel>;
    final now = DateTime.now();
    final todayOrders = completedOrders.where((order) {
      final completedAt = order.completedAt?.toLocal();
      if (completedAt == null) return false;
      return completedAt.year == now.year &&
          completedAt.month == now.month &&
          completedAt.day == now.day;
    }).toList()
      ..sort((a, b) {
        final aTime = a.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

    return _EarningsViewData(
      summary: summary,
      todayOrders: todayOrders,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _earningsFuture = _loadEarningsData();
    });
    try {
      await _earningsFuture;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thu nhap'),
        backgroundColor: Colors.deepOrange,
      ),
      body: FutureBuilder<_EarningsViewData>(
        future: _earningsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Khong tai duoc du lieu thu nhap.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final data = snapshot.data!;
          final summary = data.summary;
          final todayOrders = data.todayOrders;

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.45,
                  children: [
                    StatCard(
                      title: 'Thu nhap hom nay',
                      value: _currency.format(summary.today),
                      icon: Icons.today_outlined,
                    ),
                    StatCard(
                      title: 'Thu nhap tuan',
                      value: _currency.format(summary.week),
                      icon: Icons.calendar_view_week_outlined,
                    ),
                    StatCard(
                      title: 'Thu nhap thang',
                      value: _currency.format(summary.month),
                      icon: Icons.calendar_month_outlined,
                    ),
                    StatCard(
                      title: 'Tong so don',
                      value: '${summary.totalOrders}',
                      icon: Icons.local_shipping_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                StatCard(
                  title: 'Thu nhap trung binh / don',
                  value: _currency.format(summary.averagePerOrder),
                  icon: Icons.trending_up_outlined,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cac don da chay hom nay',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (todayOrders.isEmpty)
                          const Text('Hom nay chua co don nao hoan thanh.')
                        else
                          ...todayOrders.map(
                            (order) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => OrderDetailScreen(
                                        orderId: order.id,
                                        orderService: widget.orderService,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7ED),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              order.restaurant?.name ??
                                                  'Nha hang',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              order.deliveryAddressDisplay,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Hoan thanh luc ${_timeFormat.format(order.completedAt?.toLocal() ?? DateTime.now())}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black45,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            _currency.format(order.earning),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.deepOrange,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            color: Colors.black38,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
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

class _EarningsViewData {
  const _EarningsViewData({
    required this.summary,
    required this.todayOrders,
  });

  final EarningsSummary summary;
  final List<OrderModel> todayOrders;
}
