import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/dish.dart';
import '../../providers/favorite_provider.dart';
import '../../services/dish.dart';
import 'details_screen.dart';

class Favorites extends StatefulWidget {
  const Favorites({super.key});

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  late Future<List<Product>> _dishesFuture;

  @override
  void initState() {
    super.initState();
    _dishesFuture = DishService.fetchDishes();
  }

  Widget _buildImage(Product product) {
    final img = product.img;
    if (img == null || img.isEmpty) {
      return Container(
        color: const Color(0xFFFFF1DD),
        child: const Icon(Icons.fastfood_rounded, color: Color(0xFFE67E22)),
      );
    }
    if (img.startsWith('data:image')) {
      return Image.memory(base64Decode(img.split(',').last), fit: BoxFit.cover);
    }
    return Image.network(img, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFFFFAF0);
    const cardBg = Colors.white;
    const accent = Color(0xFFE67E22);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text('Yeu thich'),
        backgroundColor: pageBg,
      ),
      body: Consumer<FavoriteProvider>(
        builder: (context, favoriteProvider, _) => FutureBuilder<List<Product>>(
          future: _dishesFuture,
          builder: (context, snapshot) {
            if (!favoriteProvider.isLoaded ||
                snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: accent));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Khong tai duoc danh sach mon: ${snapshot.error}'));
            }

            final dishes = snapshot.data ?? [];
            final favoriteDishes = dishes
                .where((product) => favoriteProvider.isFavorite(product.id))
                .toList();

            if (favoriteDishes.isEmpty) {
              return const Center(child: Text('Chua co mon nao trong yeu thich'));
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoriteDishes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (_, index) {
                final product = favoriteDishes[index];

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DetailsScreen(product: product)),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                child: SizedBox(width: double.infinity, child: _buildImage(product)),
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: InkWell(
                                  onTap: () async {
                                    try {
                                      await favoriteProvider.toggleFavorite(product.id);
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Khong cap nhat duoc yeu thich: $e')),
                                      );
                                    }
                                  },
                                  child: const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.favorite,
                                      size: 16,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                          child: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          child: Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
