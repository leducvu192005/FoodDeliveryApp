import 'package:flutter/material.dart';
import '../../../../models/dish.dart';
import '../../../../services/dish.dart';
import '../product_card.dart';
import 'package:flutter_application_1/screen/Buyer/details_screen.dart';

class Foodpage extends StatelessWidget {
  final int categoryId;
  final String categoryName;

  const Foodpage({
    required this.categoryId,
    required this.categoryName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: Colors.deepOrange,
      ),
      body: FutureBuilder<List<Product>>(
        future: DishService.fetchDishesByCategory(categoryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Lỗi tải món ăn'));
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(child: Text('Không có món nào'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              return ProductCard(
                product: products[index],
                onAdd: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã thêm ${products[index].name}'),
                      duration: const Duration(milliseconds: 600),
                    ),
                  );
                },
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailsScreen(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
