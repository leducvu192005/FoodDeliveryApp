import 'dart:async';

import 'package:flutter_application_1/models/order_model.dart';
import 'package:flutter_application_1/models/restaurant_model.dart';

import 'auth_services.dart';
import 'shipper_api_client.dart';

class OrderService {
  OrderService({ShipperApiClient? apiClient})
      : _apiClient = apiClient ?? ShipperApiClient();

  final ShipperApiClient _apiClient;

  Stream<List<OrderModel>> streamNewOrders() async* {
    while (true) {
      yield await getAllOrders();
      await Future<void>.delayed(const Duration(seconds: 8));
    }
  }

  Future<List<OrderModel>> getAllOrders() async {
    final data = await _apiClient.get(
      '/orders/all',
      token: await _requireToken(),
    );
    return (data as List<dynamic>)
        .map((item) => _orderFromLegacyJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<List<OrderModel>> getAvailableOrders() async {
    final data = await _apiClient.get(
      '/orders/available',
      token: await _requireToken(),
    );
    return (data as List<dynamic>)
        .map((item) => _orderFromLegacyJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<List<OrderModel>> getActiveOrders() async {
    final data = await _apiClient.get(
      '/orders/current',
      token: await _requireToken(),
    );
    final payload = data as Map<String, dynamic>;
    final orderRaw = payload['order'];
    if (orderRaw == null) {
      return const <OrderModel>[];
    }
    return <OrderModel>[
      _orderFromLegacyJson(Map<String, dynamic>.from(orderRaw as Map)),
    ];
  }

  Future<OrderModel> getOrderDetail(String orderId) async {
    final data = await _apiClient.get(
      '/orders/$orderId',
      token: await _requireToken(),
    );
    return _orderFromDetailJson(data as Map<String, dynamic>);
  }

  Future<void> acceptOrder({
    required String orderId,
  }) async {
    await _apiClient.post(
      '/orders/$orderId/accept',
      token: await _requireToken(),
    );
  }

  Future<void> markOrderDelivering({
    required String orderId,
  }) async {
    await _apiClient.post(
      '/orders/$orderId/pickup',
      token: await _requireToken(),
    );
  }

  Future<void> markOrderCompleted({
    required String orderId,
  }) async {
    await _apiClient.post(
      '/orders/$orderId/deliver',
      token: await _requireToken(),
    );
  }

  Future<void> setShipperOnline({
    required bool isOnline,
  }) async {
    await _apiClient.post(
      isOnline ? '/shipper/go-online' : '/shipper/go-offline',
      token: await _requireToken(),
    );
  }

  Future<ShipperDashboardStats> getDashboardStats() async {
    final data = await _apiClient.get(
      '/shipper/dashboard',
      token: await _requireToken(),
    );
    final payload = data as Map<String, dynamic>;

    return ShipperDashboardStats(
      isOnline: payload['is_online'] == true,
      ordersToday: _toInt(payload['completed_orders_today']),
      earningsToday: _toDouble(payload['today_earnings']),
      totalOrders: _toInt(payload['total_orders']),
      onlineDuration: Duration(minutes: _toInt(payload['online_minutes_today'])),
    );
  }

  Future<EarningsSummary> getEarningsSummary() async {
    final data = await _apiClient.get(
      '/shipper/earnings/summary',
      token: await _requireToken(),
    );
    final payload = data as Map<String, dynamic>;
    return EarningsSummary(
      today: _toDouble(payload['today']),
      week: _toDouble(payload['week']),
      month: _toDouble(payload['month']),
      totalOrders: _toInt(payload['total_orders']),
      averagePerOrder: _toDouble(payload['average_per_order']),
    );
  }

  Future<ShipperProfileModel> getShipperProfile() async {
    final data = await _apiClient.get(
      '/shipper/profile',
      token: await _requireToken(),
    );
    final payload = data as Map<String, dynamic>;
    return ShipperProfileModel(
      id: (payload['shipper_id'] ?? '').toString(),
      fullName: (payload['name'] ?? '').toString(),
      email: (payload['email'] ?? '').toString(),
      phone: (payload['phone'] ?? '').toString(),
      address: (payload['address'] ?? '').toString(),
      rating: _toDouble(payload['rating']),
      completedOrders: _toInt(payload['completed_orders']),
      completionRate: _toDouble(payload['completion_rate']),
    );
  }

  Future<ShipperProfileModel> updateShipperProfile({
    String? fullName,
    String? phone,
    String? address,
  }) async {
    final data = await _apiClient.put(
      '/shipper/profile',
      token: await _requireToken(),
      body: <String, dynamic>{
        if (fullName != null) 'name': fullName,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
      },
    );
    final payload = data as Map<String, dynamic>;
    return ShipperProfileModel(
      id: (payload['shipper_id'] ?? '').toString(),
      fullName: (payload['name'] ?? '').toString(),
      email: (payload['email'] ?? '').toString(),
      phone: (payload['phone'] ?? '').toString(),
      address: (payload['address'] ?? '').toString(),
      rating: _toDouble(payload['rating']),
      completedOrders: _toInt(payload['completed_orders']),
      completionRate: _toDouble(payload['completion_rate']),
    );
  }

  Future<List<OrderModel>> getCompletedOrders({
    String search = '',
  }) async {
    final data = await _apiClient.get(
      '/orders/history',
      token: await _requireToken(),
    );
    final payload = data as Map<String, dynamic>;
    final rows = (payload['orders'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => _orderFromLegacyJson(Map<String, dynamic>.from(item as Map)))
        .where((order) => order.status == OrderStatus.completed)
        .toList();

    final keyword = search.trim().toLowerCase();
    if (keyword.isEmpty) {
      return rows;
    }

    return rows.where((order) {
      final restaurant = order.restaurant?.name.toLowerCase() ?? '';
      final customer = order.customer?.fullName.toLowerCase() ?? '';
      final address = order.deliveryAddress.toLowerCase();
      final orderId = order.id.toLowerCase();
      return restaurant.contains(keyword) ||
          customer.contains(keyword) ||
          address.contains(keyword) ||
          orderId.contains(keyword);
    }).toList();
  }

  Future<String> _requireToken() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Vui long dang nhap lai.');
    }
    return token;
  }

  OrderModel _orderFromDetailJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map(
          (item) => OrderItemModel(
            id: (item['id'] ?? '').toString(),
            orderId: (json['id'] ?? '').toString(),
            menuItemId: '',
            itemName: (item['dish_name'] ?? 'Mon an').toString(),
            quantity: _toInt(item['quantity']),
            unitPrice: _toDouble(item['unit_price']),
          ),
        )
        .toList();
    return _orderFromLegacyJson(json, items: items);
  }

  OrderModel _orderFromLegacyJson(
    Map<String, dynamic> json, {
    List<OrderItemModel> items = const <OrderItemModel>[],
  }) {
    final pickupAddress = (json['pickup_address'] ?? '').toString();
    final deliveryAddress = (json['delivery_address'] ?? '').toString();
    final restaurantNameRaw = (json['restaurant_name'] ?? '').toString().trim();
    final restaurantName = restaurantNameRaw.isEmpty || restaurantNameRaw == pickupAddress
        ? 'Diem lay hang'
        : restaurantNameRaw;
    final customerName = (json['customer_name'] ?? 'Khach hang').toString();
    final customerPhone = (json['customer_phone'] ?? '').toString();
    final shippingFee = _toDouble(json['shipping_fee'] ?? json['delivery_fee']);
    final totalPrice = _toDouble(json['total_price']);
    final normalizedStatus =
        _normalizeStatusForUi((json['status'] ?? OrderStatus.pending.dbValue).toString());
    final itemCount = items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return OrderModel.fromMap(
      <String, dynamic>{
        'id': (json['id'] ?? '').toString(),
        'customer_id': '',
        'restaurant_id': '',
        'shipper_id': 'self',
        'status': normalizedStatus,
        'delivery_address': deliveryAddress,
        'customer_phone': customerPhone,
        'distance_km': _toDouble(json['distance_km']),
        'shipping_fee': shippingFee,
        'subtotal': totalPrice,
        'total_amount': totalPrice + shippingFee,
        'estimated_minutes': _toInt(json['estimated_delivery_minutes']),
        'ordered_at': json['created_at'],
        'picked_up_at': null,
        'completed_at': json['delivered_at'],
      },
      restaurant: RestaurantModel(
        id: '',
        name: restaurantName,
        address: pickupAddress,
        phone: '',
      ),
      customer: UserModel(
        id: '',
        fullName: customerName,
        email: '',
        phone: customerPhone,
        address: deliveryAddress,
        rating: 0,
        isOnline: false,
        onlineSince: null,
        completedOrders: 0,
        completionRate: 0,
      ),
      items: items,
      itemCount: itemCount,
    );
  }

  String _normalizeStatusForUi(String status) {
    switch (status) {
      case 'confirmed':
      case 'ready_for_pickup':
        return OrderStatus.preparing.dbValue;
      case 'accepted':
        return OrderStatus.pickedUp.dbValue;
      case 'picked_up':
        return OrderStatus.delivering.dbValue;
      case 'delivered':
        return OrderStatus.completed.dbValue;
      default:
        return status;
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
