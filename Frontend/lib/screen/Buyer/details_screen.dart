import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/dish.dart';
import '../../services/cart_services.dart';
import '../../services/dish.dart';

class DetailsScreen extends StatefulWidget {
  final Product product;

  const DetailsScreen({super.key, required this.product});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final CartServices _cartServices = CartServices();
  bool _adding = false;
  late Future<List<Product>> _suggestedFuture;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _suggestedFuture = _loadSuggestedDishes();
  }

  Future<List<Product>> _loadSuggestedDishes() async {
    final sellerId = widget.product.sellerId;
    if (sellerId == null) return [];

    final dishes = await DishService.fetchDishesBySeller(sellerId);
    final currentCategoryId = widget.product.categoryId;
    final filtered = dishes.where((d) => d.id != widget.product.id).toList();

    filtered.sort((a, b) {
      final aSameCategory = a.categoryId == currentCategoryId ? 1 : 0;
      final bSameCategory = b.categoryId == currentCategoryId ? 1 : 0;
      return bSameCategory.compareTo(aSameCategory);
    });

    return filtered.take(6).toList();
  }

  Future<void> _addToCart() async {
    setState(() {
      _adding = true;
    });
    try {
      final ok = await _cartServices.addToCart(
        dishId: widget.product.id,
        quantity: _quantity,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Da them $_quantity ${widget.product.name} vao gio'
                : 'Khong the them vao gio',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loi them gio hang: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _adding = false;
        });
      }
    }
  }

  Widget _buildProductImage(Product product) {
    final img = product.img;
    if (img == null || img.isEmpty) {
      return Container(
        color: const Color(0xFFFFF1DD),
        child: const Icon(Icons.fastfood_rounded,
            size: 80, color: Color(0xFFE67E22)),
      );
    }

    if (img.startsWith('data:image')) {
      final bytes = base64Decode(img.split(',').last);
      return Image.memory(bytes, fit: BoxFit.cover);
    }

    return Image.network(img, fit: BoxFit.cover);
  }

  Widget _buildSuggestedItem(Product product) {
    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DetailsScreen(product: product)),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
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
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: _buildProductImage(product),
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
                  color: Color(0xFFE67E22),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      appBar: AppBar(
        title: const Text('Chi tiet mon an'),
        backgroundColor: const Color(0xFFFFFAF0),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
                height: 260, child: _buildProductImage(widget.product)),
          ),
          const SizedBox(height: 16),
          Text(
            widget.product.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${widget.product.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE67E22),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            (widget.product.description ?? '').trim().isEmpty
                ? 'Mon an duoc cap nhat truc tiep tu du lieu backend.'
                : widget.product.description!,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'So luong',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Chon so mon muon them vao gio',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1DD),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _adding || _quantity <= 1
                            ? null
                            : () {
                                setState(() {
                                  _quantity--;
                                });
                              },
                        icon: const Icon(Icons.remove_rounded),
                        color: const Color(0xFFE67E22),
                      ),
                      SizedBox(
                        width: 34,
                        child: Text(
                          '$_quantity',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _adding
                            ? null
                            : () {
                                setState(() {
                                  _quantity++;
                                });
                              },
                        icon: const Icon(Icons.add_rounded),
                        color: const Color(0xFFE67E22),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _adding ? null : _addToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE67E22),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: _adding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.add_shopping_cart_rounded),
            label: Text(_adding ? 'Dang them...' : 'Them vao gio'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Mon goi y cung quan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<Product>>(
            future: _suggestedFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFE67E22)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const Text(
                  'Khong tai duoc mon goi y.',
                  style: TextStyle(color: Colors.black54),
                );
              }

              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Text(
                  'Chua co mon goi y tu quan nay.',
                  style: TextStyle(color: Colors.black54),
                );
              }

              return SizedBox(
                height: 190,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  itemBuilder: (_, index) => _buildSuggestedItem(items[index]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
