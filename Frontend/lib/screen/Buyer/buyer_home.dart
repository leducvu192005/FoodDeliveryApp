import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/coupon.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'product_card.dart';
import 'category/category.dart';
import '../../models/dish.dart';
import 'package:flutter_application_1/services/dish.dart';
import 'package:flutter_application_1/services/cart_services.dart';
import 'details_screen.dart';

class BuyerHome extends StatefulWidget {
  const BuyerHome({super.key});

  @override
  State<BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  // location
  String _locationText = 'Đang xác định vị trí...';
  bool _locating = true;
  final CartServices _cartServices = CartServices();
  @override
  void initState() {
    super.initState();

    _determineAndSetLocation();
  }

  // Xác định vị trí và cập nhật địa chỉ hiển thị
  Future<void> _determineAndSetLocation() async {
    try {
      print('[location] start _determineAndSetLocation');
      // 1. Check GPS
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('[location] serviceEnabled=$serviceEnabled');
      if (!serviceEnabled) {
        setState(() {
          _locationText = 'Bật GPS';
          _locating = false;
        });
        return;
      }

      // 2. Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // 🔴 QUAN TRỌNG: check lại SAU khi request
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationText = 'Chưa cấp quyền vị trí';
          _locating = false;
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationText = 'Vào cài đặt để cấp quyền vị trí';
          _locating = false;
        });
        return;
      }

      print('[location] permission=$permission');

      // 3. Lấy tọa độ
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('[location] position=${position.latitude},${position.longitude}');

      // 4. Reverse geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final district = p.subAdministrativeArea ?? '';
        final city = p.administrativeArea ?? '';

        setState(() {
          _locationText =
              district.isNotEmpty ? '$district, $city' : 'Vị trí hiện tại';
          _locating = false;
        });
      } else {
        setState(() {
          _locationText = 'Vị trí hiện tại';
          _locating = false;
        });
      }
    } catch (e) {
      print('[location] error: $e');
      if (!mounted) return;
      setState(() {
        _locationText = 'Không lấy được vị trí';
        _locating = false;
      });
    }
  }

  Future<List<Coupon>> fetchCoupons() async {
    final res = await http.get(
      Uri.parse('http://10.0.2.2:8000/coupons/active'),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Coupon.fromJson(e)).toList();
    } else
      throw Exception('Failed to load coupons');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: const Color.fromRGBO(255, 87, 34, 1),
        titleSpacing: 16,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Giao đến:",
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
            ),
            Row(
              children: [
                /*S   if (_locating)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  ),
                if (_locating) const SizedBox(width: 6),
*/
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.white70),
                    Text(
                      _locationText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search products...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              SizedBox(
                // 2
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(width: 12),
                    categoryItem(
                      icon: Icons.fastfood,
                      label: "Food",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                Foodpage(categoryId: 1, categoryName: "Food"),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 20),
                    categoryItem(
                      icon: Icons.local_drink,
                      label: "Drink",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                Foodpage(categoryId: 2, categoryName: "Drink"),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 20),
                    categoryItem(
                      icon: Icons.restaurant,
                      label: "Fast Food",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Foodpage(
                              categoryId: 3,
                              categoryName: "Fast Food",
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 20),
                    categoryItem(
                      icon: Icons.rice_bowl,
                      label: "Cơm",
                      onTap: (() {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                Foodpage(categoryId: 4, categoryName: "Com"),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 20),
                    categoryItem(
                      icon: Icons.local_offer,
                      label: "Khuyến mãi",
                      onTap: (() {}),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 420,
                child: FutureBuilder<List<Product>>(
                  future: DishService.fetchDishes().then(
                    (data) => data.cast<Product>(),
                  ),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return const Center(child: Text('Lỗi tải sản phẩm'));
                    }

                    final List<Product> products = snap.data ?? [];

                    if (products.isEmpty) {
                      return const Center(child: Text('Không có sản phẩm'));
                    }

                    return GridView.builder(
                      itemCount: products.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (context, i) => ProductCard(
                        product: products[i],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailsScreen(),
                            ),
                          );
                        },
                        onAdd: () async {
                          await _cartServices.addToCart(
                            dishId: products[i].id,
                            quantity: 1,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã thêm ${products[i].name}'),
                              duration: Duration(milliseconds: 800),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 400),
            ],
          ),
        ),
      ),
    );
  }
}

//widget category item
Widget categoryItem({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 250, 232, 232),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(
            icon,
            color: const Color.fromARGB(255, 255, 60, 1),
            size: 30,
          ),
        ),
        SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    ),
  );
}
