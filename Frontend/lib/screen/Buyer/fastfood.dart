import 'package:flutter/material.dart';

class Fastfood extends StatefulWidget {
  const Fastfood({super.key});

  @override
  State<Fastfood> createState() => _FastfoodState();
}

class _FastfoodState extends State<Fastfood> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fast Food')),
      body: const Center(child: Text('Fast Food Page')),
    );
  }
}
