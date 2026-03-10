import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/cart_services.dart';
import 'package:flutter_application_1/services/discount_services.dart';
import 'package:flutter_application_1/services/payment_services.dart';
import 'package:geocoding/geocoding.dart';

enum _CheckoutPaymentMethod { cod, sepay }

extension on _CheckoutPaymentMethod {
  String get apiValue {
    switch (this) {
      case _CheckoutPaymentMethod.cod:
        return 'cod';
      case _CheckoutPaymentMethod.sepay:
        return 'sepay';
    }
  }

  String get title {
    switch (this) {
      case _CheckoutPaymentMethod.cod:
        return 'Thanh toan khi nhan hang';
      case _CheckoutPaymentMethod.sepay:
        return 'Chuyen khoan ngan hang';
    }
  }

  String get subtitle {
    switch (this) {
      case _CheckoutPaymentMethod.cod:
        return 'Tao don ngay, thanh toan khi shipper giao den.';
      case _CheckoutPaymentMethod.sepay:
        return 'Chuyen khoan qua QR code. Don duoc xac nhan sau khi nhan tien.';
    }
  }

  IconData get icon {
    switch (this) {
      case _CheckoutPaymentMethod.cod:
        return Icons.payments_outlined;
      case _CheckoutPaymentMethod.sepay:
        return Icons.qr_code_2_outlined;
    }
  }
}

class Cart extends StatefulWidget {
  const Cart({
    super.key,
    this.initialAddress,
    this.initialLat,
    this.initialLng,
  });

  final String? initialAddress;
  final double? initialLat;
  final double? initialLng;

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  final CartServices _cartServices = CartServices();
  final Map<int, TextEditingController> _noteControllers = {};
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _cartFuture;
  bool _isPaying = false;
  _CheckoutPaymentMethod _selectedPaymentMethod = _CheckoutPaymentMethod.cod;
  bool _isResolvingLocation = false;
  String? _currentLocationAddress;
  double? _currentLat;
  double? _currentLng;
  double _discountAmountValue = 0;
  String? _discountMessage;
  bool _isValidatingPromo = false;

  @override
  void initState() {
    super.initState();
    _cartFuture = _cartServices.getCartItems();
    // Use location from home if available, otherwise fetch GPS
    if (widget.initialAddress != null &&
        widget.initialLat != null &&
        widget.initialLng != null) {
      _currentLocationAddress = widget.initialAddress;
      _currentLat = widget.initialLat;
      _currentLng = widget.initialLng;
      _addressController.text = widget.initialAddress!;
    }
  }

  @override
  void dispose() {
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    _promoController.dispose();
    _addressController.dispose();
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

  double _calculateDistanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return (earthRadius * c * 100).roundToDouble() / 100;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  double _deliveryFee(List<Map<String, dynamic>> items) {
    if (_currentLat == null || _currentLng == null) return 0;
    final sellerLat = items.isNotEmpty
        ? (items.first['seller_lat'] as num?)?.toDouble()
        : null;
    final sellerLng = items.isNotEmpty
        ? (items.first['seller_lng'] as num?)?.toDouble()
        : null;
    if (sellerLat == null || sellerLng == null) return 0;
    final distanceKm =
        _calculateDistanceKm(sellerLat, sellerLng, _currentLat!, _currentLng!);
    if (distanceKm <= 3) return 15000;
    return (distanceKm * 5000).roundToDouble();
  }

  double _discountAmount() {
    return _discountAmountValue;
  }

  double _grandTotal(List<Map<String, dynamic>> items) {
    final total = _itemsTotal(items);
    final fee = _deliveryFee(items);
    final discount = _discountAmount();
    return (total + fee - discount).clamp(0, 999999999);
  }

  Future<void> _showAvailableDiscounts(
      List<Map<String, dynamic>> cartItems) async {
    final sellerId = cartItems.isNotEmpty
        ? (cartItems.first['seller_id'] as num?)?.toInt()
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _DiscountListSheet(
          sellerId: sellerId,
          onSelect: (code) {
            _promoController.text = code;
            Navigator.pop(ctx);
            _validatePromoCode(cartItems);
          },
        );
      },
    );
  }

  Future<void> _validatePromoCode(List<Map<String, dynamic>> cartItems) async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _discountAmountValue = 0;
        _discountMessage = null;
      });
      return;
    }

    setState(() => _isValidatingPromo = true);

    try {
      final itemsTotal = _itemsTotal(cartItems);
      final sellerId = cartItems.isNotEmpty
          ? (cartItems.first['seller_id'] as num?)?.toInt()
          : null;

      final result = await DiscountService.validateDiscountCode(
        code: code,
        cartTotal: itemsTotal,
        sellerId: sellerId,
      );

      if (!mounted) return;
      final valid = result['valid'] == true;
      setState(() {
        _discountAmountValue =
            valid ? (result['discount_amount'] as num?)?.toDouble() ?? 0 : 0;
        _discountMessage = result['message']?.toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _discountAmountValue = 0;
        _discountMessage = 'Khong the kiem tra ma giam gia';
      });
    } finally {
      if (mounted) setState(() => _isValidatingPromo = false);
    }
  }

  Future<void> _placeOrder() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final isSepay = _selectedPaymentMethod == _CheckoutPaymentMethod.sepay;

    setState(() {
      _isPaying = true;
    });

    try {
      if (_currentLat == null || _currentLng == null) {
        throw Exception(
            'Chua xac dinh duoc vi tri giao hang. Vui long nhap dia chi.');
      }
      final deliveryAddress = _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : _currentLocationAddress ?? '';

      // Collect notes from all items
      final notes = <String>[];
      for (final entry in _noteControllers.entries) {
        final text = entry.value.text.trim();
        if (text.isNotEmpty) {
          notes.add(text);
        }
      }
      final note = notes.isNotEmpty ? notes.join(' | ') : null;

      final checkoutResult = await _cartServices.checkout(
        deliveryAddress: deliveryAddress,
        deliveryLat: _currentLat!,
        deliveryLng: _currentLng!,
        method: _selectedPaymentMethod.apiValue,
        note: note,
        discountCode:
            _discountAmountValue > 0 ? _promoController.text.trim() : null,
      );

      final orderId = checkoutResult['order_id'];
      if (orderId == null) {
        throw Exception('Khong nhan duoc order_id tu server');
      }

      if (!isSepay) {
        // COD: done
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

      // SePay: show QR payment dialog
      if (!mounted) return;
      final paymentService = PaymentServices();
      await paymentService.processSepayPayment(context, orderId as int);

      if (!mounted) return;
      messenger.showSnackBar(
          const SnackBar(content: Text('Thanh toan thanh cong!')));
      _refreshCart();
      navigator.pushNamed('/buyer/order');
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final isCanceled = isSepay &&
          (msg.contains('canceled') ||
              msg.contains('cancelled') ||
              msg.contains('huy'));
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
            content: Text(isCanceled
                ? 'Ban da huy thanh toan'
                : '${isSepay ? 'Thanh toan that bai' : 'Dat don that bai'}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPaying = false;
        });
      }
    }
  }

  Future<void> _geocodeEditedAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    setState(() => _isResolvingLocation = true);
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) {
        throw Exception('Khong tim thay toa do');
      }
      final loc = locations.first;
      if (!mounted) return;
      setState(() {
        _currentLocationAddress = address;
        _currentLat = loc.latitude;
        _currentLng = loc.longitude;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Khong xac dinh duoc dia chi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isResolvingLocation = false);
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
          final deliveryFee = _deliveryFee(cartItems);
          final discount = _discountAmount();
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
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: accent),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Dia chi giao hang',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Nhap dia chi giao hang...',
                        filled: true,
                        fillColor: const Color(0xFFFFF6EA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Icon(Icons.edit_location_alt_outlined,
                              color: Colors.black45),
                        ),
                        suffixIcon: IconButton(
                          onPressed: _isResolvingLocation
                              ? null
                              : _geocodeEditedAddress,
                          icon: const Icon(Icons.check_circle_outline,
                              color: accent),
                          tooltip: 'Xac nhan dia chi',
                        ),
                      ),
                      onSubmitted: (_) => _geocodeEditedAddress(),
                    ),
                    if (_currentLat != null && _currentLng != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Toa do: ${_currentLat!.toStringAsFixed(5)}, ${_currentLng!.toStringAsFixed(5)}',
                          style: const TextStyle(
                              color: Colors.black45, fontSize: 12),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showAvailableDiscounts(cartItems),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF6EA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:
                                const Icon(Icons.sell_outlined, color: accent),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _promoController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'Nhap ma giam gia',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFFFF6EA),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isValidatingPromo
                              ? null
                              : () => _validatePromoCode(cartItems),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          child: _isValidatingPromo
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Ap dung'),
                        ),
                      ],
                    ),
                    if (_discountMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _discountMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: _discountAmountValue > 0
                                ? const Color(0xFF2E7D32)
                                : Colors.redAccent,
                          ),
                        ),
                      ),
                  ],
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
                        label: 'Tong mon',
                        value: '${itemsTotal.toStringAsFixed(0)}d'),
                    _PriceRow(
                        label: 'Phi giao hang',
                        value: '${deliveryFee.toStringAsFixed(0)}d'),
                    _PriceRow(
                      label: 'Giam gia',
                      value: '- ${discount.toStringAsFixed(0)}d',
                      valueColor: const Color(0xFF2E7D32),
                    ),
                    const Divider(color: Color(0x1A000000), height: 18),
                    _PriceRow(
                      label: 'Tong cong',
                      value: '${grandTotal.toStringAsFixed(0)}d',
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
                      method: _CheckoutPaymentMethod.sepay,
                      selectedMethod: _selectedPaymentMethod,
                      accent: accent,
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod = _CheckoutPaymentMethod.sepay;
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
                      ? _selectedPaymentMethod == _CheckoutPaymentMethod.sepay
                          ? 'Dang xu ly thanh toan...'
                          : 'Dang tao don...'
                      : _selectedPaymentMethod == _CheckoutPaymentMethod.sepay
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

/// Bottom sheet hiển thị danh sách mã giảm giá khả dụng
class _DiscountListSheet extends StatefulWidget {
  const _DiscountListSheet({required this.sellerId, required this.onSelect});
  final int? sellerId;
  final void Function(String code) onSelect;

  @override
  State<_DiscountListSheet> createState() => _DiscountListSheetState();
}

class _DiscountListSheetState extends State<_DiscountListSheet> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = DiscountService.getActiveDiscountCodes(sellerId: widget.sellerId);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF5A623);
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Ma giam gia kha dung',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final codes = snapshot.data ?? [];
                  if (codes.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sell_outlined,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Khong co ma giam gia nao',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: codes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final c = codes[index];
                      final code = c['code'] ?? '';
                      final title = c['title'] ?? code;
                      final desc = c['description'] ?? '';
                      final type = c['discount_type'];
                      final value = c['discount_value'] ?? 0;
                      final minOrder = c['min_order_value'] ?? 0;
                      final endAt = c['end_at'];
                      final forUser = c['user_id'];

                      String discountText;
                      if (type == 'percent') {
                        discountText = 'Giam ${(value as num).toInt()}%';
                      } else {
                        discountText =
                            'Giam ${_formatVnd((value as num).toDouble())}';
                      }

                      return InkWell(
                        onTap: () => widget.onSelect(code),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF6EA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accent.withAlpha(80)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: accent.withAlpha(40),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.sell,
                                    color: accent, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      code,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (title != code)
                                      Text(title,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54)),
                                    const SizedBox(height: 4),
                                    Text(
                                      discountText,
                                      style: const TextStyle(
                                        color: accent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if ((minOrder as num) > 0)
                                      Text(
                                        'Don toi thieu: ${_formatVnd((minOrder).toDouble())}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black45),
                                      ),
                                    if (desc.isNotEmpty)
                                      Text(desc,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black45)),
                                    if (endAt != null)
                                      Text(
                                        'Het han: ${_formatDate(endAt)}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.redAccent),
                                      ),
                                    if (forUser != null)
                                      const Text(
                                        'Danh rieng cho ban',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF2E7D32),
                                            fontWeight: FontWeight.w500),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  static String _formatVnd(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf}d';
  }

  static String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
