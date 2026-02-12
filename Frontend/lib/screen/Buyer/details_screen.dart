import 'package:flutter/material.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết món ăn'),
        backgroundColor: Colors.deepOrange,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: Icon(
                    Icons.fastfood,
                    size: 100,
                    color: Colors.deepOrange,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
