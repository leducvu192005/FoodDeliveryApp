import 'package:flutter/material.dart';

class OrderShipper extends StatefulWidget {
  const OrderShipper({super.key});

  @override
  State<OrderShipper> createState() => _OrderShipperState();
}

class _OrderShipperState extends State<OrderShipper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: const Text("Order Shipper Screen"),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("this is order shipper screen"),
          ],
        ),
      ),
    );
  }
}
