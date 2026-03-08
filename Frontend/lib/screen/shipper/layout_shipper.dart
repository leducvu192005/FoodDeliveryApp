import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/shipper/shipper_home_screen.dart';
import 'package:flutter_application_1/screen/shipper/order_history_screen.dart';
import 'package:flutter_application_1/screen/shipper/earnings_screen.dart';
import 'package:flutter_application_1/screen/shipper/profile_screen.dart';
import 'package:flutter_application_1/services/order_service.dart';

class ShipperLayout extends StatefulWidget {
  const ShipperLayout({super.key});

  @override
  State<ShipperLayout> createState() => _ShipperLayoutState();
}

class _ShipperLayoutState extends State<ShipperLayout>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _historyRefreshTick = 0;
  int _earningsRefreshTick = 0;
  late final OrderService _orderService;
  bool _offlineSyncing = false;

  @override
  void initState() {
    super.initState();

    _orderService = OrderService();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _markShipperOffline();
    }
  }

  Future<void> _markShipperOffline() async {
    if (_offlineSyncing) return;
    _offlineSyncing = true;
    try {
      await _orderService.setShipperOnline(isOnline: false);
    } catch (_) {
    } finally {
      _offlineSyncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ShipperHomeScreen(
            orderService: _orderService,
          ),
          OrderHistoryScreen(
            orderService: _orderService,
            refreshTick: _historyRefreshTick,
          ),
          EarningsScreen(
            orderService: _orderService,
            refreshTick: _earningsRefreshTick,
          ),
          ProfileScreen(orderService: _orderService),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            if (index == 1) {
              _historyRefreshTick++;
            } else if (index == 2) {
              _earningsRefreshTick++;
            }
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Lịch sử',
          ),
          NavigationDestination(
            icon: Icon(Icons.attach_money_outlined),
            selectedIcon: Icon(Icons.attach_money),
            label: 'Thu nhập',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
