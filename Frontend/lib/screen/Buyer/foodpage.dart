import 'package:flutter/material.dart';

import '../../models/dish.dart';
import '../../services/dish.dart';
import 'details_screen.dart';
import 'product_card.dart';

class Foodpage extends StatelessWidget {
  const Foodpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      appBar: AppBar(
        title: const Text('Food'),
        backgroundColor: const Color(0xFFFFFAF0),
      ),
      body: FutureBuilder<List<Product>>(
        future: DishService.fetchDishes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE67E22)));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Loi tai danh sach mon'));
          }

          final dishes = snapshot.data ?? [];
          if (dishes.isEmpty) {
            return const Center(child: Text('Khong co mon nao'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: dishes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (_, index) {
              final product = dishes[index];
              return ProductCard(
                product: product,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailsScreen(product: product)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
