import 'package:flutter/material.dart';

class BuyerHome extends StatelessWidget {
  const BuyerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buyer Home")),
      body: const Center(child: Text("Welcome to the Buyer Home Screen!")),
    );
  }
}
