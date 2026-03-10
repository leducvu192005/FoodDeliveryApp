import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import '../../config/api_config.dart';
import '../../models/dish.dart';
import '../../services/auth_services.dart';
import '../../services/cart_services.dart';
import 'details_screen.dart';
import 'product_card.dart';

class ProgramDishesScreen extends StatefulWidget {
  final int programId;
  final String programTitle;
  final Position? buyerPosition;

  const ProgramDishesScreen({
    super.key,
    required this.programId,
    required this.programTitle,
    this.buyerPosition,
  });

  @override
  State<ProgramDishesScreen> createState() => _ProgramDishesScreenState();
}

class _ProgramDishesScreenState extends State<ProgramDishesScreen> {
  static const double _deliveryRadiusKm = 5;
  final CartServices _cartServices = CartServices();
  List<Product> _dishes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDishes();
  }

  Future<void> _loadDishes() async {
    setState(() => _loading = true);
    try {
      final token = await AuthService.getToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final res = await http.get(
        Uri.parse(ApiConfig.path(
            '/display/buyer/programs/${widget.programId}/dishes')),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final all = data
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();

        // Filter by radius if buyer position available
        final filtered = widget.buyerPosition != null
            ? all.where(_isWithinRadius).toList()
            : all;

        if (mounted) setState(() => _dishes = filtered);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isWithinRadius(Product product) {
    final position = widget.buyerPosition;
    if (position == null ||
        product.sellerLat == null ||
        product.sellerLng == null) {
      return false;
    }
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      product.sellerLat!,
      product.sellerLng!,
    );
    return distance <= _deliveryRadiusKm * 1000;
  }

  Future<void> _addToCart(Product product) async {
    try {
      final ok = await _cartServices.addToCart(dishId: product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Da them ${product.name}'
              : 'Khong them duoc ${product.name}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loi them gio: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      appBar: AppBar(
        title: Text(widget.programTitle),
        backgroundColor: const Color(0xFFFFFAF0),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE67E22)))
          : _dishes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Chua co mon an nao trong chuong trinh nay'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDishes,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_dishes.length} mon an',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: GridView.builder(
                            itemCount: _dishes.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.74,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemBuilder: (_, i) {
                              final product = _dishes[i];
                              return ProductCard(
                                product: product,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DetailsScreen(product: product),
                                    ),
                                  );
                                },
                                onAdd: () => _addToCart(product),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
