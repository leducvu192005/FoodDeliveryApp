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

class _ShipperLayoutState extends State<ShipperLayout> {
  int _currentIndex = 0;
  late final OrderService _orderService;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();

    _orderService = OrderService();

    _tabs = [
      ShipperHomeScreen(
        orderService: _orderService,
      ),
      OrderHistoryScreen(orderService: _orderService),
      EarningsScreen(orderService: _orderService),
      ProfileScreen(orderService: _orderService),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
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
