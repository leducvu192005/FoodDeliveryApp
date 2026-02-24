import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/dish.dart';
import '../../services/cart_services.dart';

class DetailsScreen extends StatefulWidget {
  final Product product;

  const DetailsScreen({super.key, required this.product});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final CartServices _cartServices = CartServices();
  bool _adding = false;

  Future<void> _addToCart() async {
    setState(() {
      _adding = true;
    });
    try {
      final ok = await _cartServices.addToCart(dishId: widget.product.id, quantity: 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Da them ${widget.product.name} vao gio' : 'Khong the them vao gio'),
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

  Widget _buildImage() {
    final img = widget.product.img;
    if (img == null || img.isEmpty) {
      return Container(
        color: const Color(0xFFFFF1DD),
        child: const Icon(Icons.fastfood_rounded, size: 80, color: Color(0xFFE67E22)),
      );
    }

    if (img.startsWith('data:image')) {
      final bytes = base64Decode(img.split(',').last);
      return Image.memory(bytes, fit: BoxFit.cover);
    }

    return Image.network(img, fit: BoxFit.cover);
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
            child: SizedBox(height: 260, child: _buildImage()),
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
          const Text(
            'Mon an duoc cap nhat truc tiep tu du lieu backend.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _adding ? null : _addToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE67E22),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: _adding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.add_shopping_cart_rounded),
            label: Text(_adding ? 'Dang them...' : 'Them vao gio'),
          ),
        ],
      ),
    );
  }
}
