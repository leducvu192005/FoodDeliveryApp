import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/coupon.dart';
import 'package:flutter_application_1/services/product_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'product_card.dart';
import 'foodpage.dart';
import 'drinkpage.dart';

class BuyerHome extends StatefulWidget {
  const BuyerHome({super.key});

  @override
  State<BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  // location
  String _locationText = 'Đang xác định vị trí...';
  bool _locating = true;

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
          _locationText = district.isNotEmpty
              ? '$district, $city'
              : 'Vị trí hiện tại';
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
        backgroundColor: const Color.fromRGBO(255, 87, 34, 1),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_locating)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  ),
                if (_locating) const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _locationText,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.black),
                  hintText: ' Search products...',
                  hintStyle: const TextStyle(color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Lấy lại vị trí',
            onPressed: () async {
              setState(() {
                _locating = true;
                _locationText = 'Đang xác định vị trí...';
              });
              await _determineAndSetLocation();
            },
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              SizedBox(
                // Category items
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
                          MaterialPageRoute(builder: (_) => const Foodpage()),
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
                          MaterialPageRoute(builder: (_) => const Drinkpage()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 420,
                child: FutureBuilder<List>(
                  future: ProductService.fetchProducts(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Lỗi tải sản phẩm'));
                    }
                    final products = snap.data ?? [];
                    if (products.isEmpty)
                      return Center(child: Text('Không có sản phẩm'));
                    return GridView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.66,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, i) => ProductCard(
                        product: products[i],
                        onTap: () {
                          // ví dụ: mở trang chi tiết (tạo route /product nếu cần)
                          // Navigator.pushNamed(context, '/product', arguments: products[i]);
                        },
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 120,
                child: FutureBuilder<List<Coupon>>(
                  future: fetchCoupons(),
                  builder: (context, snap) {
                    if (!snap.hasData)
                      return Center(child: CircularProgressIndicator());
                    final coupons = snap.data!;
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      itemCount: coupons.length,
                      separatorBuilder: (_, __) => SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final c = coupons[idx];
                        return Container(
                          width: 260,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 6),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  c.discountType == 'percent'
                                      ? '${c.discountValue.toStringAsFixed(0)}%'
                                      : '${c.discountValue.toStringAsFixed(0)}đ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      c.title ?? c.code,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      c.description ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            elevation: 0,
                                            backgroundColor: Colors.deepOrange,
                                          ),
                                          onPressed: () async {
                                            // gọi validate endpoint
                                            final resp = await http.post(
                                              Uri.parse(
                                                'http://10.0.2.2:8000/coupons/validate',
                                              ),
                                              headers: {
                                                'Content-Type':
                                                    'application/json',
                                              },
                                              body: jsonEncode({
                                                'code': c.code,
                                                'cart_total': 100000,
                                              }),
                                            );
                                            // xử lý kết quả: show dialog/toast
                                          },
                                          child: Text('Áp dụng'),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Min ${(c.minOrderValue ?? 0).toStringAsFixed(0)}đ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
            color: Colors.deepOrange,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    ),
  );
}
