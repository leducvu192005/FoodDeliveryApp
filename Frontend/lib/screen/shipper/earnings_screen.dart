import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/order_model.dart';
import 'package:flutter_application_1/services/order_service.dart';
import 'package:flutter_application_1/widgets/stat_card.dart';
import 'package:intl/intl.dart';

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
  late Future<EarningsSummary> _earningsFuture;

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _earningsFuture = widget.orderService.getEarningsSummary();
  }

  @override
  void didUpdateWidget(covariant EarningsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.refreshTick ?? 0) != (oldWidget.refreshTick ?? 0)) {
      _reload();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _earningsFuture = widget.orderService.getEarningsSummary();
    });
    try {
      await _earningsFuture;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thu nhập')),
      body: FutureBuilder<EarningsSummary>(
        future: _earningsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Không tải được dữ liệu thu nhập.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final data = snapshot.data!;
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
                      title: 'Thu nhập hôm nay',
                      value: _currency.format(data.today),
                      icon: Icons.today_outlined,
                    ),
                    StatCard(
                      title: 'Thu nhập tuần',
                      value: _currency.format(data.week),
                      icon: Icons.calendar_view_week_outlined,
                    ),
                    StatCard(
                      title: 'Thu nhập tháng',
                      value: _currency.format(data.month),
                      icon: Icons.calendar_month_outlined,
                    ),
                    StatCard(
                      title: 'Tổng số đơn',
                      value: '${data.totalOrders}',
                      icon: Icons.local_shipping_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                StatCard(
                  title: 'Thu nhập trung bình / đơn',
                  value: _currency.format(data.averagePerOrder),
                  icon: Icons.trending_up_outlined,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
