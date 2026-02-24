import 'package:flutter/material.dart';

import '../../models/dish.dart';
import '../../services/cart_services.dart';
import '../../services/dish.dart';
import 'details_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final int categoryId;
  final String title;

  const RestaurantDetailScreen({
    super.key,
    required this.categoryId,
    required this.title,
  });

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final CartServices _cartServices = CartServices();

  Future<void> _addToCart(Product product) async {
    final ok = await _cartServices.addToCart(dishId: product.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Da them ${product.name}' : 'Khong them duoc mon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFFFFFAF0),
      ),
      body: FutureBuilder<List<Product>>(
        future: DishService.fetchDishesByCategory(widget.categoryId),
        builder: (_, snapshot) {
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

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: dishes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final product = dishes[index];
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(product.name),
                subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFFE67E22)),
                  onPressed: () => _addToCart(product),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DetailsScreen(product: product)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
