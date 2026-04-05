import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/category.dart';
import '../../models/dish.dart';
import '../../services/cart_services.dart';
import '../../services/auth_services.dart';
import '../../services/category_services.dart';
import '../../services/dish.dart';
import 'cart.dart';
import 'category/category.dart';
import 'details_screen.dart';
import 'product_card.dart';
import 'program_dishes_screen.dart';

class BuyerHome extends StatefulWidget {
  const BuyerHome({super.key});

  @override
  State<BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  static const double _deliveryRadiusKm = 5;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final CartServices _cartServices = CartServices();
  late Future<Map<String, dynamic>> _homeDataFuture;

  Position? _currentPosition;
  String? _currentLocationText;
  String? _locationError;
  bool _isLocating = false;
  bool _isEditingAddress = false;

  List<Map<String, dynamic>> _displayPrograms = [];
  final Map<int, List<Product>> _programDishes = {};

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _loadData();
    _searchController.addListener(() => setState(() {}));
    _loadCurrentLocation();
    _loadDisplayPrograms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final token = await AuthService.getToken();
    print(
        '[BuyerHome] Token: ${token != null ? "${token.substring(0, 20)}..." : "NULL"}');

    final results = await Future.wait([
      CategoryService.fetchCategories(),
      DishService.fetchDishes(),
    ]);

    final categories = results[0] as List<Category>;
    final dishes = results[1] as List<Product>;
    print(
        '[BuyerHome] Categories: ${categories.length}, Dishes: ${dishes.length}');
    for (final d in dishes) {
      print(
          '[BuyerHome] Dish: ${d.name}, seller_id=${d.sellerId}, sellerLat=${d.sellerLat}, sellerLng=${d.sellerLng}');
    }

    return {
      'categories': categories,
      'dishes': dishes,
    };
  }

  Future<void> _refresh() async {
    setState(() {
      _homeDataFuture = _loadData();
    });
    await _homeDataFuture;
    _loadDisplayPrograms();
  }

  Future<void> _loadDisplayPrograms() async {
    try {
      final token = await AuthService.getToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      final res = await http.get(
        Uri.parse(ApiConfig.path('/display/buyer/programs')),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final programs = data.cast<Map<String, dynamic>>();
        if (mounted) {
          setState(() => _displayPrograms = programs);
        }
        // Load dishes for each program
        for (final p in programs) {
          final pid = p['id'] as int;
          final dishRes = await http.get(
            Uri.parse(ApiConfig.path('/display/buyer/programs/$pid/dishes')),
            headers: headers,
          );
          if (dishRes.statusCode == 200) {
            final List<dynamic> dishData = jsonDecode(dishRes.body);
            final dishes = dishData
                .map((e) => Product.fromJson(e as Map<String, dynamic>))
                .toList();
            if (mounted) {
              setState(() => _programDishes[pid] = dishes);
            }
          }
        }
      }
    } catch (e) {
      print('[BuyerHome] Error loading display programs: $e');
    }
  }

  Future<void> _loadCurrentLocation() async {
    if (mounted) {
      setState(() {
        _isLocating = true;
        _locationError = null;
      });
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Hay bat dich vu vi tri de xem mon an gan ban');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Ban chua cap quyen vi tri');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Quyen vi tri da bi tu choi vinh vien');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final address = await _reverseGeocodeAddress(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _currentLocationText = address;
        _addressController.text = address;
        _locationError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentPosition = null;
        _currentLocationText = null;
        _locationError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLocating = false;
      });
    }
  }

  Future<String> _reverseGeocodeAddress(
      double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final parts = <String>[
          if ((placemark.street ?? '').trim().isNotEmpty)
            placemark.street!.trim(),
          if ((placemark.subAdministrativeArea ?? '').trim().isNotEmpty)
            placemark.subAdministrativeArea!.trim(),
          if ((placemark.administrativeArea ?? '').trim().isNotEmpty)
            placemark.administrativeArea!.trim(),
        ];
        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
    } catch (_) {}

    return 'Lat ${latitude.toStringAsFixed(5)}, Lng ${longitude.toStringAsFixed(5)}';
  }

  Future<void> _geocodeCustomAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) {
        throw Exception('Khong tim thay toa do tu dia chi nay');
      }
      final loc = locations.first;
      final position = Position(
        latitude: loc.latitude,
        longitude: loc.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _currentLocationText = address;
        _locationError = null;
        _isEditingAddress = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLocating = false);
    }
  }

  bool _isWithinRadius(Product product) {
    final position = _currentPosition;
    final sellerLat = product.sellerLat;
    final sellerLng = product.sellerLng;

    if (position == null || sellerLat == null || sellerLng == null) {
      print('[DEBUG] ${product.name} (seller_id=${product.sellerId}): '
          'SKIP - position=$position, sellerLat=$sellerLat, sellerLng=$sellerLng');
      return false;
    }

    final distanceMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      sellerLat,
      sellerLng,
    );

    final withinRadius = distanceMeters <= _deliveryRadiusKm * 1000;
    print('[DEBUG] ${product.name} (seller_id=${product.sellerId}): '
        'buyer=(${position.latitude}, ${position.longitude}), '
        'seller=($sellerLat, $sellerLng), '
        'distance=${(distanceMeters / 1000).toStringAsFixed(2)}km, '
        'show=$withinRadius');

    return withinRadius;
  }

  Future<void> _addToCart(Product product) async {
    try {
      final ok = await _cartServices.addToCart(dishId: product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Da them ${product.name}' : 'Khong them duoc ${product.name}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loi them gio: $e')),
      );
    }
  }

  List<Widget> _buildCollectionSection() {
    final widgets = <Widget>[];
    for (final p in _displayPrograms) {
      final pid = p['id'] as int;
      final dishes = _programDishes[pid] ?? [];
      if (dishes.isEmpty) continue;

      widgets.addAll([
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mon an hot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProgramDishesScreen(
                      programId: pid,
                      programTitle: p['title'] ?? '',
                      buyerPosition: _currentPosition,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    'Xem tat ca',
                    style: TextStyle(
                      color: Colors.deepOrange[400],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      size: 18, color: Colors.deepOrange[400]),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dishes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final product = dishes[i];
              return SizedBox(
                width: 160,
                child: ProductCard(
                  product: product,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsScreen(product: product),
                      ),
                    );
                  },
                  onAdd: () => _addToCart(product),
                ),
              );
            },
          ),
        ),
      ]);
    }
    return widgets;
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
        elevation: 0,
        title: const Text('Hom nay ban muon an gi?'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Cart(
                  initialAddress: _currentLocationText,
                  initialLat: _currentPosition?.latitude,
                  initialLng: _currentPosition?.longitude,
                ),
              ),
            ),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _homeDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: accent),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Khong tai duoc du lieu: ${snapshot.error}',
                  style: const TextStyle(color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final categories =
              (snapshot.data?['categories'] as List<Category>? ?? []);
          final allDishes = (snapshot.data?['dishes'] as List<Product>? ?? []);
          final nearbyDishes = allDishes.where(_isWithinRadius).toList();
          final keyword = _searchController.text.trim().toLowerCase();
          final dishes = keyword.isEmpty
              ? nearbyDishes
              : nearbyDishes
                  .where((d) => d.name.toLowerCase().contains(keyword))
                  .toList();

          return RefreshIndicator(
            color: accent,
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tim mon an...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD580), Color(0xFFFF9F43)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${nearbyDishes.length} mon trong ban kinh ${_deliveryRadiusKm.toStringAsFixed(0)}km - ${categories.length} danh muc',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFFE2BE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child:
                                Icon(Icons.my_location_rounded, color: accent),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Vi tri hien tai',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (!_isEditingAddress)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isEditingAddress = true;
                                  _addressController.text =
                                      _currentLocationText ?? '';
                                });
                              },
                              icon: const Icon(
                                Icons.edit_location_alt_outlined,
                                size: 18,
                                color: accent,
                              ),
                              label: const Text(
                                'Doi dia chi',
                                style: TextStyle(color: accent),
                              ),
                            ),
                          if (!_isEditingAddress)
                            TextButton.icon(
                              onPressed:
                                  _isLocating ? null : _loadCurrentLocation,
                              icon: _isLocating
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: accent,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.gps_fixed_rounded,
                                      size: 18,
                                      color: accent,
                                    ),
                              label: const Text(
                                'GPS',
                                style: TextStyle(color: accent),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (_isEditingAddress) ...[
                        TextField(
                          controller: _addressController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Nhap dia chi moi...',
                            filled: true,
                            fillColor: const Color(0xFFFFF6EA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: _isLocating
                                      ? null
                                      : _geocodeCustomAddress,
                                  icon: const Icon(Icons.check_circle_outline,
                                      color: accent),
                                  tooltip: 'Xac nhan',
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditingAddress = false;
                                    });
                                  },
                                  icon: const Icon(Icons.close_rounded,
                                      color: Colors.black45),
                                  tooltip: 'Huy',
                                ),
                              ],
                            ),
                          ),
                          onSubmitted: (_) => _geocodeCustomAddress(),
                        ),
                        if (_locationError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _locationError!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ] else
                        Text(
                          _isLocating
                              ? 'Dang xac dinh vi tri...'
                              : _currentLocationText ??
                                  _locationError ??
                                  'Khong lay duoc vi tri hien tai',
                          style: TextStyle(
                            color: _locationError == null
                                ? Colors.black54
                                : Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_displayPrograms.isNotEmpty) ..._buildCollectionSection(),
                const SizedBox(height: 16),
                const Text(
                  'Danh muc',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final c = categories[i];
                      return ActionChip(
                        backgroundColor: cardBg,
                        side: const BorderSide(color: Color(0xFFFFE2BE)),
                        label: Text(c.name),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Foodpage(
                                categoryId: c.id,
                                categoryName: c.name,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Mon an gan ban',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (_currentPosition == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        _isLocating
                            ? 'Dang tai vi tri de loc mon an...'
                            : _locationError ??
                                'Can vi tri hien tai de hien thi mon an gan ban',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else if (dishes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        keyword.isEmpty
                            ? 'Khong co mon an nao trong ban kinh 5km'
                            : 'Khong tim thay mon an phu hop trong 5km',
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    itemCount: dishes.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.74,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (_, i) {
                      final product = dishes[i];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailsScreen(product: product),
                            ),
                          );
                        },
                        onAdd: () => _addToCart(product),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
