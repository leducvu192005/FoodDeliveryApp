import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'package:flutter_application_1/services/cart_services.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_application_1/services/payment_services.dart';
>>>>>>> 392c371 (làm giao diện giỏ hàng và xử lí thanh toán)

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
<<<<<<< HEAD
=======
  final CartServices _cartServices = CartServices();
  late Future<List<Map<String, dynamic>>> _cartFuture;
  Uint8List imageFromBase64(String base64String) {
    final pureBase64 = base64String.split(',').last;
    return base64Decode(pureBase64);
  }

  @override
  void initState() {
    super.initState();
    _cartFuture = _cartServices.getCartItems();
  }

  void refreshCart() {
    setState(() {
      _cartFuture = _cartServices.getCartItems();
    });
  }

  // --- SỬA LỖI 1: Hàm tính tổng tiền an toàn ---
  double totalPrice(List<Map<String, dynamic>> items) {
    double total = 0;
    for (var item in items) {
      // Lấy object dish ra trước
      final dish = item['dish'] ?? {};

      // Lấy giá và số lượng an toàn (ép kiểu num rồi sang double/int)
      final price = (dish['price'] as num?)?.toDouble() ?? 0.0;
      final quantity = (item['quantity'] as num?)?.toInt() ?? 1;

      total += price * quantity;
    }
    return total;
  }

>>>>>>> 392c371 (làm giao diện giỏ hàng và xử lí thanh toán)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
<<<<<<< HEAD
        backgroundColor: Colors.deepOrange,
        title: const Text('Cart'),
      ),
      body: const Center(child: Text('This is the Cart Screen')),
=======
        title: const Text('Giỏ hàng'),
        backgroundColor: Colors.deepOrange,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // In lỗi ra console để dễ debug nếu có
            print("Lỗi UI: ${snapshot.error}");
            return const Center(child: Text('Lỗi tải giỏ hàng'));
          }

          final cartItems = snapshot.data ?? [];

          if (cartItems.isEmpty) {
            return const Center(child: Text('Giỏ hàng trống'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    final dish = item['dish'] ?? {};
                    final quantity = item['quantity'] ?? 1;

                    // Xử lý ảnh và tên
                    final imgUrl = dish['img'] ?? '';
                    final name = dish['name'] ?? 'Món không tên';
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
                            // Ảnh món ăn

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
                            // Thông tin tên và giá
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
                                    "${price.toStringAsFixed(0)} đ",
                                    style: const TextStyle(
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Các nút bấm tăng giảm
                            Column(
                              children: [
                                // Nút Tăng
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle,
                                    color: Colors.green,
                                  ),
                                  onPressed: () async {
                                    // Gọi API update (cộng dồn)
                                    await _cartServices.updateQuantity(
                                      item['dish_id'], // dish_id nằm ở root
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
                                // Nút Giảm
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
                            // Nút Xóa hẳn
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
              // Phần Tổng tiền dưới đáy
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
                      "Tổng tiền: ${totalPrice(cartItems).toStringAsFixed(0)} đ",
                      style: TextStyle(
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
                        onPressed: () async {
                          try {
                            final paymentService = PaymentServices();

                            // 1️⃣ Tạo order
                            final checkoutResult =
                                await _cartServices.checkout();

                            final orderId = checkoutResult["order_id"];

                            if (orderId == null) {
                              throw Exception(
                                  "Không nhận được order_id từ server");
                            }
                            print(checkoutResult);

                            // 2️⃣ Thanh toán Stripe
                            await paymentService.processPayment(orderId);

                            // 3️⃣ Hiển thị thành công
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Thanh toán thành công 🎉")),
                            );

                            refreshCart();
                          } catch (e) {
                            print("Lỗi thanh toán: $e");

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Thanh toán thất bại: $e")),
                            );
                          }
                        },
                        child: Text(
                          "Thanh toán",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ))
                    /* Text(
                      "${totalPrice(cartItems).toStringAsFixed(0)} đ",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ), */
                  ],
                ),
              ),
            ],
          );
        },
      ),
>>>>>>> 392c371 (làm giao diện giỏ hàng và xử lí thanh toán)
    );
  }
}
