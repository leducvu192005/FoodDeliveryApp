import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/cart_services.dart';
import 'package:flutter_application_1/services/payment_services.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  final CartServices _cartServices = CartServices();
  final Map<int, TextEditingController> _noteControllers = {};
  final TextEditingController _promoController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _cartFuture;
  bool _isPaying = false;

  static const double _deliveryFee = 1.5;

  @override
  void initState() {
    super.initState();
    _cartFuture = _cartServices.getCartItems();
  }

  @override
  void dispose() {
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    _promoController.dispose();
    super.dispose();
  }

  Uint8List _imageFromBase64(String base64String) {
    final pureBase64 = base64String.split(',').last;
    return base64Decode(pureBase64);
  }

  void _refreshCart() {
    setState(() {
      _cartFuture = _cartServices.getCartItems();
    });
  }

  double _itemsTotal(List<Map<String, dynamic>> items) {
    double total = 0;
    for (final item in items) {
      final dish = item['dish'] ?? {};
      final price = (dish['price'] as num?)?.toDouble() ?? 0.0;
      final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
      total += price * quantity;
    }
    return total;
  }

  double _discountAmount(double itemsTotal) {
    final promo = _promoController.text.trim().toUpperCase();
    if (promo == 'SAVE10') return itemsTotal * 0.1;
    if (promo == 'FREESHIP') return _deliveryFee;
    return 0;
  }

  double _grandTotal(List<Map<String, dynamic>> items) {
    final total = _itemsTotal(items);
    final discount = _discountAmount(total);
    return (total + _deliveryFee - discount).clamp(0, 999999);
  }

  Future<void> _placeOrder() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isPaying = true;
    });

    try {
      final paymentService = PaymentServices();
      final checkoutResult = await _cartServices.checkout();
      final orderId = checkoutResult['order_id'];

      if (orderId == null) {
        throw Exception('Khong nhan duoc order_id tu server');
      }

      // Sử dụng Sepay payment thay vì Stripe
      if (!mounted) return;
      await paymentService.processSepayPayment(context, orderId);

      // Dialog đã tự động kiểm tra và chỉ đóng khi thanh toán thành công
      // Nếu đến đây nghĩa là thanh toán đã thành công
      if (!mounted) return;

      messenger.showSnackBar(
          const SnackBar(content: Text('Thanh toan thanh cong!')));
      _refreshCart();

      // Chuyển sang trang orders
      navigator.pushReplacementNamed('/buyer/order');
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final isCanceled = msg.contains('canceled') ||
          msg.contains('cancelled') ||
          msg.contains('huy');
      messenger.showSnackBar(
        SnackBar(
            content: Text(isCanceled
                ? 'Ban da huy thanh toan'
                : 'Thanh toan that bai: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPaying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFFFFAF0);
    const cardBg = Colors.white;
    const accent = Color(0xFFE67E22);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        title: const Text('Gio hang'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: accent));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Loi tai gio hang'));
          }

          final cartItems = snapshot.data ?? [];
          if (cartItems.isEmpty) {
            return const Center(child: Text('Gio hang trong'));
          }

          final itemsTotal = _itemsTotal(cartItems);
          final discount = _discountAmount(itemsTotal);
          final grandTotal = _grandTotal(cartItems);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            children: [
              ...cartItems.map((item) {
                final dish = item['dish'] ?? {};
                final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
                final dishId = (item['dish_id'] as num).toInt();
                final imgUrl = dish['img'] ?? '';
                final name = dish['name'] ?? 'Mon khong ten';
                final price = (dish['price'] as num?)?.toDouble() ?? 0.0;

                final noteController = _noteControllers.putIfAbsent(
                    dishId, () => TextEditingController());

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imgUrl.isNotEmpty
                                ? Image.memory(
                                    _imageFromBase64(imgUrl),
                                    width: 82,
                                    height: 82,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 82,
                                      height: 82,
                                      color: const Color(0xFFFFF1DD),
                                      child: const Icon(Icons.fastfood,
                                          color: Colors.black45),
                                    ),
                                  )
                                : Container(
                                    width: 82,
                                    height: 82,
                                    color: const Color(0xFFFFF1DD),
                                    child: const Icon(Icons.fastfood,
                                        color: Colors.black45),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '\$${price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      color: accent,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () async {
                                  if (quantity > 1) {
                                    await _cartServices.updateQuantity(
                                        dishId, quantity - 1);
                                    _refreshCart();
                                  }
                                },
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.black54),
                              ),
                              Text(
                                '$quantity',
                                style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w700),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await _cartServices.updateQuantity(
                                      dishId, quantity + 1);
                                  _refreshCart();
                                },
                                icon: const Icon(Icons.add_circle_outline,
                                    color: accent),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteController,
                        decoration: InputDecoration(
                          hintText: 'Ghi chu mon an...',
                          filled: true,
                          fillColor: const Color(0xFFFFF6EA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.edit_note_rounded,
                              color: Colors.black45),
                          suffixIcon: IconButton(
                            onPressed: () async {
                              await _cartServices.removeFromCart(dishId);
                              _refreshCart();
                            },
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _promoController,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Ma giam gia (SAVE10/FREESHIP)',
                    prefixIcon: const Icon(Icons.sell_outlined, color: accent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFFF6EA),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _PriceRow(
                        label: 'Items total',
                        value: '\$${itemsTotal.toStringAsFixed(2)}'),
                    _PriceRow(
                        label: 'Delivery fee',
                        value: '\$${_deliveryFee.toStringAsFixed(2)}'),
                    _PriceRow(
                      label: 'Discount',
                      value: '- \$${discount.toStringAsFixed(2)}',
                      valueColor: const Color(0xFF2E7D32),
                    ),
                    const Divider(color: Color(0x1A000000), height: 18),
                    _PriceRow(
                      label: 'Grand total',
                      value: '\$${grandTotal.toStringAsFixed(2)}',
                      labelStyle: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      valueStyle: const TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _isPaying ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _isPaying ? 'Dang xu ly thanh toan...' : 'Dat don',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final Color? valueColor;

  const _PriceRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: labelStyle ??
                const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
          ),
          Text(
            value,
            style: valueStyle ??
                TextStyle(
                  color: valueColor ?? Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
