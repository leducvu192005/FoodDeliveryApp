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

  // ✅ Khởi tạo danh sách screens một lần
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const SellerHomeScreen(),
      const OrderScreen(),
      const MenuScreen(),
      const MarketingScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Dùng IndexedStack thay vì truy cập trực tiếp _screens[_currentIndex]
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // ✅ Thêm debug để kiểm tra
          print('Tapped: $index');
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        // ✅ Thêm backgroundColor để rõ hơn
        backgroundColor: Colors.white,
        elevation: 8,
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