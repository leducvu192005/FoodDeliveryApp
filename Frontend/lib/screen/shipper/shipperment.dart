import 'package:flutter/material.dart';
class Shipperment extends StatefulWidget {
  const Shipperment({super.key});

  @override
  State<Shipperment> createState() => _ShippermentState();
}

class _ShippermentState extends State<Shipperment> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: const Text("Shipperment Screen"),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("this is shipperment screen"),
          ],
        ),
      ),
    );
  }
}