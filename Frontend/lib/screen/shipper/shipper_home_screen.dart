import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/order_model.dart';
import 'package:flutter_application_1/screen/shipper/order_detail_screen.dart';
import 'package:flutter_application_1/services/order_service.dart';
import 'package:flutter_application_1/widgets/order_card.dart';
import 'package:flutter_application_1/widgets/stat_card.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class ShipperHomeScreen extends StatefulWidget {
  final OrderService orderService;

  const ShipperHomeScreen({
    super.key,
    required this.orderService,
  });

  @override
  State<ShipperHomeScreen> createState() => _ShipperHomeScreenState();
}

class _ShipperHomeScreenState extends State<ShipperHomeScreen> {
  late Future<ShipperDashboardStats> _statsFuture;
  late Future<List<OrderModel>> _activeOrdersFuture;

  bool _busy = false;
  bool _isOnline = false;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _locationTimer;
  DateTime? _lastLocationSentAt;
  String? _shipperId;

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'd',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _prepareOverview();
    unawaited(_syncTrackingWithServer());
  }

  @override
  void dispose() {
    unawaited(_stopLocationTracking());
    super.dispose();
  }

  void _prepareOverview() {
    _statsFuture = _loadDashboardStats();
    _activeOrdersFuture = widget.orderService.getActiveOrders();
  }

  Future<ShipperDashboardStats> _loadDashboardStats() async {
    final stats = await widget.orderService.getDashboardStats();
    if (mounted && _isOnline != stats.isOnline) {
      setState(() => _isOnline = stats.isOnline);
    } else {
      _isOnline = stats.isOnline;
    }
    return stats;
  }

  Future<void> _syncTrackingWithServer() async {
    try {
      final profile = await widget.orderService.getShipperProfile();
      _shipperId = profile.id;
      if (mounted) {
        setState(() => _isOnline = profile.isOnline);
      } else {
        _isOnline = profile.isOnline;
      }
      if (profile.id.isNotEmpty && profile.isOnline && mounted) {
        await _startLocationTracking();
      }
    } catch (_) {}
  }

  Future<void> _refreshAll() async {
    setState(_prepareOverview);

    await Future.wait([
      _statsFuture,
      _activeOrdersFuture,
    ]);
  }

  Future<void> _setOnline(bool value) async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      if (value) {
        await _ensureLocationReady();
      }

      await widget.orderService.setShipperOnline(
        isOnline: value,
      );
      if (mounted) {
        setState(() => _isOnline = value);
      } else {
        _isOnline = value;
      }

      if (value) {
        await _startLocationTracking();
      } else {
        await _stopLocationTracking();
      }

      await _refreshAll();
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _acceptOrder(OrderModel order) async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      await widget.orderService.acceptOrder(
        orderId: order.id,
      );

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(
            orderId: order.id,
            orderService: widget.orderService,
          ),
        ),
      );

      await _refreshAll();
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _openOrderDetail(String orderId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: orderId,
          orderService: widget.orderService,
        ),
      ),
    );

    await _refreshAll();
  }

  bool _canAcceptOrder(OrderModel order) {
    return order.status == OrderStatus.pending ||
        order.status == OrderStatus.confirmed;
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes <= 0) return '0 phut';

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours == 0) return '$minutes phut';

    return '$hours gio $minutes phut';
  }

  Future<void> _ensureLocationReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Hay bat dich vu vi tri tren thiet bi.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Ung dung can quyen vi tri de nhan don.');
    }

    if (_shipperId == null || _shipperId!.isEmpty) {
      final profile = await widget.orderService.getShipperProfile();
      _shipperId = profile.id;
    }
  }

  Future<void> _startLocationTracking() async {
    await _ensureLocationReady();
    await _stopLocationTracking();

    final currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    await _pushLocation(currentPosition);

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 30,
      ),
    ).listen((position) {
      unawaited(_maybePushLocation(position));
    });

    _locationTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        await _maybePushLocation(position, force: true);
      } catch (_) {}
    });
  }

  Future<void> _stopLocationTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _locationTimer?.cancel();
    _locationTimer = null;
    _lastLocationSentAt = null;
  }

  Future<void> _maybePushLocation(
    Position position, {
    bool force = false,
  }) async {
    if (!force &&
        _lastLocationSentAt != null &&
        DateTime.now().difference(_lastLocationSentAt!) <
            const Duration(seconds: 15)) {
      return;
    }
    await _pushLocation(position);
  }

  Future<void> _pushLocation(Position position) async {
    await widget.orderService.updateShipperLocation(
      shipperId: _shipperId,
      lat: position.latitude,
      lng: position.longitude,
    );
    _lastLocationSentAt = DateTime.now();
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 0,
        title: const Text('Giao hang ngay nao!'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            FutureBuilder<ShipperDashboardStats>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Khong tai duoc thong ke.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final stats = snapshot.data!;

                return Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stats.isOnline
                                        ? 'Dang online'
                                        : 'Dang offline',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Thoi gian online: ${_formatDuration(stats.onlineDuration)}',
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: stats.isOnline,
                              onChanged: _busy ? null : _setOnline,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.45,
                      children: [
                        StatCard(
                          title: 'Don hom nay',
                          value: '${stats.ordersToday}',
                          icon: Icons.today_outlined,
                        ),
                        StatCard(
                          title: 'Thu nhap hom nay',
                          value: _currency.format(stats.earningsToday),
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                        StatCard(
                          title: 'Tong don',
                          value: '${stats.totalOrders}',
                          icon: Icons.assignment_outlined,
                        ),
                        StatCard(
                          title: 'Thoi gian online',
                          value: _formatDuration(stats.onlineDuration),
                          icon: Icons.schedule_outlined,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Don dang nhan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<OrderModel>>(
              future: _activeOrdersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    'Khong tai duoc don dang xu ly: ${snapshot.error}',
                  );
                }

                final activeOrders = snapshot.data ?? [];

                if (activeOrders.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        'Ban chua co don dang xu ly.',
                      ),
                    ),
                  );
                }

                return Column(
                  children: activeOrders.map((order) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OrderCard(
                        order: order,
                        onTap: () => _openOrderDetail(order.id),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Tat ca don hang',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            if (!_isOnline)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Hay bat online de hien thi don moi.',
                  ),
                ),
              )
            else
              StreamBuilder<List<OrderModel>>(
                stream: widget.orderService.streamNewOrders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Text(
                      'Khong tai duoc danh sach don hang: ${snapshot.error}',
                    );
                  }

                  final orders = snapshot.data ?? [];

                  if (orders.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Text(
                          'Hien chua co don hang.',
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: orders.map((order) {
                      final canAccept = _canAcceptOrder(order);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OrderCard(
                          order: order,
                          showAcceptButton: canAccept,
                          onAccept: _busy || !canAccept
                              ? null
                              : () => _acceptOrder(order),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
