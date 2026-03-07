import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/cart_services.dart';
import 'package:flutter_application_1/services/payment_services.dart';

enum _CheckoutPaymentMethod { cod, stripe }

extension on _CheckoutPaymentMethod {
  String get apiValue {
    switch (this) {
      case _CheckoutPaymentMethod.cod:
        return 'cod';
      case _CheckoutPaymentMethod.stripe:
        return 'stripe';
    }
  }

  String get title {
    switch (this) {
      case _CheckoutPaymentMethod.cod:
        return 'Thanh toan khi nhan hang';
      case _CheckoutPaymentMethod.stripe:
        return 'Chuyen khoan qua Stripe';
    }
  }

  String get subtitle {
    switch (this) {
      case _CheckoutPaymentMethod.cod:
        return 'Tao don ngay, thanh toan khi shipper giao den.';
      case _CheckoutPaymentMethod.stripe:
        return 'Mo Stripe de thanh toan online. Don chi duoc tao sau khi thanh toan thanh cong.';
    }
  }

  IconData get icon {
    switch (this) {
      case _CheckoutPaymentMethod.cod:
        return Icons.payments_outlined;
      case _CheckoutPaymentMethod.stripe:
        return Icons.account_balance_outlined;
    }
  }
}

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  final CartServices _cartServices = CartServices();
  final Map<int, TextEditingController> _noteControllers = {};
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _deliveryAddressController =
      TextEditingController();
  late Future<List<Map<String, dynamic>>> _cartFuture;
  bool _isPaying = false;
  _CheckoutPaymentMethod _selectedPaymentMethod = _CheckoutPaymentMethod.cod;

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
    _deliveryAddressController.dispose();
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

  Future<Map<String, dynamic>> _waitForStripeOrderCreated(
      PaymentServices paymentService, int checkoutId) async {
    Map<String, dynamic> lastResult = const {'status': 'pending'};
    for (int i = 0; i < 5; i++) {
      lastResult = await paymentService.confirmCheckout(checkoutId);
      final status = (lastResult['status'] ?? '').toString().toLowerCase();
      if (status == 'paid' && lastResult['order_id'] != null) {
        return lastResult;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    return lastResult;
  }

  Future<void> _placeOrder() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final isStripePayment =
        _selectedPaymentMethod == _CheckoutPaymentMethod.stripe;

    setState(() {
      _isPaying = true;
    });

    try {
      final paymentService = PaymentServices();
      final checkoutResult = await _cartServices.checkout(
        deliveryAddress: _deliveryAddressController.text.trim(),
        method: _selectedPaymentMethod.apiValue,
      );

      if (!isStripePayment) {
        final orderId = checkoutResult['order_id'];
        if (orderId == null) {
          throw Exception('Khong nhan duoc order_id tu server');
        }
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content:
                Text('Tao don thanh cong. Ban se thanh toan khi nhan hang.'),
          ),
        );
        _refreshCart();
        navigator.pushNamed('/buyer/order');
        return;
      }

      final rawCheckoutId = checkoutResult['checkout_id'];
      final checkoutId = rawCheckoutId is int
          ? rawCheckoutId
          : int.tryParse(rawCheckoutId?.toString() ?? '');
      final clientSecret = checkoutResult['client_secret']?.toString();

      if (checkoutId == null || clientSecret == null || clientSecret.isEmpty) {
        throw Exception('Khong nhan duoc thong tin thanh toan Stripe tu server');
      }

      await paymentService.processPaymentSheet(clientSecret);
      final paymentResult =
          await _waitForStripeOrderCreated(paymentService, checkoutId);
      final isPaid = (paymentResult['status'] ?? '').toString().toLowerCase() ==
              'paid' &&
          paymentResult['order_id'] != null;

      if (!mounted) return;

      if (isPaid) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Thanh toan thanh cong')));
        _refreshCart();
        navigator.pushNamed('/buyer/order');
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Thanh toan chua hoan tat. Don hang chua duoc tao.'),
          ),
        );
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final isCanceled = isStripePayment &&
          (msg.contains('canceled') ||
              msg.contains('cancelled') ||
              msg.contains('huy'));
      messenger.showSnackBar(
        SnackBar(
            content: Text(isCanceled
                ? 'Ban da huy thanh toan'
                : '${isStripePayment ? 'Thanh toan that bai' : 'Dat don that bai'}: $e')),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: accent),
                        SizedBox(width: 8),
                        Text(
                          'Dia chi giao hang',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _deliveryAddressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Nhap dia chi giao hang. De trong se dung dia chi trong ho so neu co.',
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 48),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFFF6EA),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
                    const SizedBox(height: 14),
                    const Divider(color: Color(0x1A000000), height: 1),
                    const SizedBox(height: 14),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Phuong thuc thanh toan',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PaymentMethodTile(
                      method: _CheckoutPaymentMethod.cod,
                      selectedMethod: _selectedPaymentMethod,
                      accent: accent,
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod = _CheckoutPaymentMethod.cod;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _PaymentMethodTile(
                      method: _CheckoutPaymentMethod.stripe,
                      selectedMethod: _selectedPaymentMethod,
                      accent: accent,
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod =
                              _CheckoutPaymentMethod.stripe;
                        });
                      },
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
                  _isPaying
                      ? _selectedPaymentMethod == _CheckoutPaymentMethod.stripe
                          ? 'Dang xu ly thanh toan...'
                          : 'Dang tao don...'
                      : _selectedPaymentMethod == _CheckoutPaymentMethod.stripe
                          ? 'Dat don va thanh toan'
                          : 'Dat don',
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

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.selectedMethod,
    required this.accent,
    required this.onTap,
  });

  final _CheckoutPaymentMethod method;
  final _CheckoutPaymentMethod selectedMethod;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = method == selectedMethod;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF3E4) : const Color(0xFFFFFBF6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accent : const Color(0x1F000000),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected ? accent.withOpacity(0.12) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                method.icon,
                color: isSelected ? accent : Colors.black54,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Radio<_CheckoutPaymentMethod>(
              value: method,
              groupValue: selectedMethod,
              activeColor: accent,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
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
