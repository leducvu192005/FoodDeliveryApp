import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/favorite_provider.dart';
import 'buyer_home.dart';
import 'favorites.dart';
import 'order.dart';
import 'profile.dart';

class Layout extends StatefulWidget {
  const Layout({super.key});

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    BuyerHome(),
    Order(),
    Favorites(),
    Profile(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FavoriteProvider>().refresh();
    });
  }

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFFFF3E0),
        currentIndex: _selectedIndex,
        onTap: _onTap,
        selectedItemColor: const Color(0xFFE67E22),
        unselectedItemColor: Colors.black45,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
