import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ShipperHomeData {
  final int id;
  final String name;
  final String phone;
  final String? avatar;
  final bool isOnline;
  final double? lat;
  final double? lng;
  final int acceptRadius;

  const ShipperHomeData({
    required this.id,
    required this.name,
    required this.phone,
    required this.avatar,
    required this.isOnline,
    required this.lat,
    required this.lng,
    required this.acceptRadius,
  });

  factory ShipperHomeData.fromJson(Map<String, dynamic> json) {
    return ShipperHomeData(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      isOnline: json['is_online'] == true,
      lat: json['lat'] == null ? null : (json['lat'] as num).toDouble(),
      lng: json['lng'] == null ? null : (json['lng'] as num).toDouble(),
      acceptRadius: (json['accept_radius'] ?? 5) as int,
    );
  }

  ShipperHomeData copyWith({
    String? name,
    String? phone,
    String? avatar,
    bool? isOnline,
    double? lat,
    double? lng,
    int? acceptRadius,
  }) {
    return ShipperHomeData(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      isOnline: isOnline ?? this.isOnline,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      acceptRadius: acceptRadius ?? this.acceptRadius,
    );
  }
}

class ShipperRealtimeOrder {
  final int orderId;
  final double? pickupLat;
  final double? pickupLng;
  final double distance;
  final double deliveryFee;

  const ShipperRealtimeOrder({
    required this.orderId,
    required this.pickupLat,
    required this.pickupLng,
    required this.distance,
    required this.deliveryFee,
  });

  factory ShipperRealtimeOrder.fromJson(Map<String, dynamic> json) {
    return ShipperRealtimeOrder(
      orderId: json['order_id'] ?? 0,
      pickupLat:
          json['pickup_lat'] == null ? null : (json['pickup_lat'] as num).toDouble(),
      pickupLng:
          json['pickup_lng'] == null ? null : (json['pickup_lng'] as num).toDouble(),
      distance: (json['distance'] ?? 0).toDouble(),
      deliveryFee: (json['delivery_fee'] ?? 0).toDouble(),
    );
  }
}

class ShipperServices {
  final String token;
  final String _baseUrl = ApiConfig.path('/shipper');

  ShipperServices({
    required this.token,
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<ShipperHomeData> fetchMe() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/me'),
      headers: _headers,
    );
    _throwIfNotSuccess(response, 'load shipper profile');
    return ShipperHomeData.fromJson(jsonDecode(response.body));
  }

  Future<void> updateOnline({
    required bool isOnline,
  }) async {
    final response = await http.post(
      Uri.parse(isOnline ? '$_baseUrl/go-online' : '$_baseUrl/go-offline'),
      headers: _headers,
    );
    _throwIfNotSuccess(response, 'update online status');
  }

  Future<void> updateRadius({
    required int radiusKm,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/radius'),
      headers: _headers,
      body: jsonEncode({
        'radius_km': radiusKm,
      }),
    );
    _throwIfNotSuccess(response, 'update receive radius');
  }

  Future<void> updateLocation({
    required double lat,
    required double lng,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/location-update'),
      headers: _headers,
      body: jsonEncode({
        'lat': lat,
        'lng': lng,
      }),
    );
    _throwIfNotSuccess(response, 'update location');
  }

  Future<Map<String, dynamic>> fetchDashboard() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/dashboard'),
      headers: _headers,
    );
    _throwIfNotSuccess(response, 'load shipper dashboard');

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final activeOrderRaw = payload['active_order'];
    final availableOrdersRaw = payload['available_orders'] as List<dynamic>? ?? <dynamic>[];

    return {
      'shipperName': payload['shipper_name']?.toString() ?? '',
      'rating': (payload['rating'] ?? 0).toDouble(),
      'isOnline': payload['is_online'] == true,
      'onlineMinutesToday': (payload['online_minutes_today'] ?? 0) as int,
      'todayEarnings': (payload['today_earnings'] ?? 0).toDouble(),
      'completedOrdersToday': (payload['completed_orders_today'] ?? 0) as int,
      'totalDistanceToday': (payload['total_distance_today'] ?? 0).toDouble(),
      'activeOrder': activeOrderRaw == null
          ? null
          : _mapDashboardOrder(Map<String, dynamic>.from(activeOrderRaw as Map)),
      'availableOrders': availableOrdersRaw
          .map(
            (item) => _mapDashboardOrder(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    };
  }

  Future<void> toggleOnline() async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/toggle-online'),
      headers: _headers,
    );
    _throwIfNotSuccess(response, 'toggle online status');
  }

  Future<void> acceptOrder(String orderId) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/orders/$orderId/accept'),
      headers: _headers,
    );
    _throwIfNotSuccess(response, 'accept order');
  }

  Future<void> pickupOrder(String orderId) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/orders/$orderId/pickup'),
      headers: _headers,
    );
    _throwIfNotSuccess(response, 'mark order as picked up');
  }

  Future<void> deliverOrder(String orderId) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/orders/$orderId/deliver'),
      headers: _headers,
    );
    _throwIfNotSuccess(response, 'mark order as delivered');
  }

  Uri buildOrdersWsUri() {
    final uri = Uri.parse(ApiConfig.path('/ws/orders'));
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri.replace(
      scheme: wsScheme,
      path: '/ws/orders',
      queryParameters: {'token': token},
    );
  }

  void _throwIfNotSuccess(http.Response response, String action) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String detail = response.body;
    try {
      final parsed = jsonDecode(response.body);
      if (parsed is Map<String, dynamic> && parsed['detail'] != null) {
        detail = parsed['detail'].toString();
      }
    } catch (_) {}
    throw Exception('Failed to $action: $detail');
  }

  Map<String, dynamic> _mapDashboardOrder(Map<String, dynamic> order) {
    return {
      'id': order['id']?.toString() ?? '',
      'customerName': order['customer_name']?.toString() ?? '',
      'customerPhone': order['customer_phone']?.toString() ?? '',
      'pickupAddress': order['pickup_address']?.toString() ?? '',
      'deliveryAddress': order['delivery_address']?.toString() ?? '',
      'deliveryFee': (order['delivery_fee'] ?? 0).toDouble(),
      'distanceKm': (order['distance_km'] ?? 0).toDouble(),
      'status': order['status']?.toString() ?? 'pending',
      'estimatedDeliveryMinutes': (order['estimated_delivery_minutes'] as num?)?.toInt(),
    };
  }
}
