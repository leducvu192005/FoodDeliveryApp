import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/Buyer/profile.dart';
import 'package:flutter_application_1/screen/shipper/order_shipper.dart';
import 'package:flutter_application_1/screen/shipper/shipperment.dart';
import 'shipper_home.dart';

class LayoutShipper extends StatefulWidget {
  const LayoutShipper({super.key});

  @override
  State<LayoutShipper> createState() => _LayoutShipperState();
}

class _LayoutShipperState extends State<LayoutShipper> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const ShipperHome(),
    const OrderShipper(),
    const Shipperment(),
    const Profile(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Order",
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.delivery_dining), label: "Shipperment"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
