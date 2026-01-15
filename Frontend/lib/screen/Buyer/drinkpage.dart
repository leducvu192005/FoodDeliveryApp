import 'package:flutter/material.dart';

class Drinkpage extends StatefulWidget {
  const Drinkpage({super.key});

  @override
  State<Drinkpage> createState() => _DrinkpageState();
}

class _DrinkpageState extends State<Drinkpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: const Text('Drink Page'),
      ),
      body: const Center(child: Text('This is the Drink Page Screen')),
    );
  }
}
