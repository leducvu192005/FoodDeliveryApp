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
  late Future<List<Map<String, dynamic>>> _cartFuture;
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    _cartFuture = _cartServices.getCartItems();
  }

  Uint8List imageFromBase64(String base64String) {
    final pureBase64 = base64String.split(',').last;
    return base64Decode(pureBase64);
  }

  void refreshCart() {
    setState(() {
      _cartFuture = _cartServices.getCartItems();
    });
  }

  double totalPrice(List<Map<String, dynamic>> items) {
    double total = 0;
    for (var item in items) {
      final dish = item['dish'] ?? {};
      final price = (dish['price'] as num?)?.toDouble() ?? 0.0;
      final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
      total += price * quantity;
    }
    return total;
  }

  Future<bool> _waitForPaymentConfirmed(
    PaymentServices paymentService,
    int orderId,
  ) async {
    for (int i = 0; i < 5; i++) {
      final status = await paymentService.checkPaymentStatus(orderId);
      if (status == 'paid') {
        return true;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gio hang'),
        backgroundColor: Colors.deepOrange,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint('Cart load error: ${snapshot.error}');
            return const Center(child: Text('Loi tai gio hang'));
          }

          final cartItems = snapshot.data ?? [];
          if (cartItems.isEmpty) {
            return const Center(child: Text('Gio hang trong'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    final dish = item['dish'] ?? {};
                    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
                    final imgUrl = dish['img'] ?? '';
                    final name = dish['name'] ?? 'Mon khong ten';
                    final price = (dish['price'] as num?)?.toDouble() ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imgUrl.isNotEmpty
                                  ? Image.memory(
                                      imageFromBase64(imgUrl),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) =>
                                          Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    )
                                  : Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.fastfood),
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${price.toStringAsFixed(0)} d',
                                    style: const TextStyle(
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle,
                                    color: Colors.green,
                                  ),
                                  onPressed: () async {
                                    await _cartServices.updateQuantity(
                                      item['dish_id'],
                                      quantity + 1,
                                    );
                                    refreshCart();
                                  },
                                ),
                                Text(
                                  quantity.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () async {
                                    if (quantity > 1) {
                                      await _cartServices.updateQuantity(
                                        item['dish_id'],
                                        quantity - 1,
                                      );
                                      refreshCart();
                                    }
                                  },
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _cartServices.removeFromCart(
                                  item['dish_id'],
                                );
                                refreshCart();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tong tien: ${totalPrice(cartItems).toStringAsFixed(0)} d',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isPaying
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);

                              setState(() {
                                _isPaying = true;
                              });

                              try {
                                final paymentService = PaymentServices();
                                final checkoutResult =
                                    await _cartServices.checkout();
                                final orderId = checkoutResult['order_id'];

                                if (orderId == null) {
                                  throw Exception(
                                      'Khong nhan duoc order_id tu server');
                                }

                                await paymentService.processPayment(orderId);
                                final isPaid = await _waitForPaymentConfirmed(
                                  paymentService,
                                  orderId,
                                );

                                if (!mounted) return;

                                if (isPaid) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Thanh toan thanh cong'),
                                    ),
                                  );
                                  refreshCart();
                                  navigator.pushNamed('/buyer/order');
                                } else {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Da tao giao dich nhung chua xac nhan thanh toan. Vui long kiem tra lai don hang.',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                debugPrint('Payment error: $e');
                                final msg = e.toString().toLowerCase();
                                final isCanceled = msg.contains('canceled') ||
                                    msg.contains('cancelled') ||
                                    msg.contains('huy');

                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isCanceled
                                          ? 'Ban da huy thanh toan'
                                          : 'Thanh toan that bai: $e',
                                    ),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isPaying = false;
                                  });
                                }
                              }
                            },
                      child: Text(
                        _isPaying ? 'Dang xu ly...' : 'Thanh toan',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
