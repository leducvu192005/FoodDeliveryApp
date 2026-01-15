import 'package:flutter/material.dart';
import 'seller/home/home.dart';
import 'seller/menu/menu.dart';
import 'seller/order/order.dart';
import 'seller/marketing/marketing.dart';
import 'seller/profile/profile.dart';

class SellerNavScreen extends StatefulWidget {
  const SellerNavScreen({super.key});

  @override
  State<SellerNavScreen> createState() => _SellerNavScreenState();
}

class _SellerNavScreenState extends State<SellerNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    SellerHomeScreen(),
    OrderScreen(),
    MenuScreen(),
    MarketingScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Đơn hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Thực đơn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            activeIcon: Icon(Icons.campaign),
            label: 'Marketing',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}