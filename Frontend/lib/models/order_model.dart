import 'package:flutter_application_1/models/restaurant_model.dart';

enum OrderStatus {
  pending,
  confirmed,
  accepted,
  pickedUp,
  delivered,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get dbValue {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.pickedUp:
        return 'picked_up';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get labelVi {
    switch (this) {
      case OrderStatus.pending:
        return 'Cho xu ly';
      case OrderStatus.confirmed:
        return 'Cho shipper nhan';
      case OrderStatus.accepted:
        return 'Shipper da nhan';
      case OrderStatus.pickedUp:
        return 'Dang giao';
      case OrderStatus.delivered:
        return 'Da giao';
      case OrderStatus.cancelled:
        return 'Da huy';
    }
  }
}

OrderStatus parseOrderStatus(String value) {
  switch (value) {
    case 'shipper':
    case 'confirmed':
    case 'ready_for_pickup':
      return OrderStatus.confirmed;
    case 'seller':
    case 'accepted':
      return OrderStatus.accepted;
    case 'picked_up':
    case 'delivering':
      return OrderStatus.pickedUp;
    case 'delivered':
    case 'completed':
    case 'done':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'pending':
    default:
      return OrderStatus.pending;
  }
}

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final double rating;
  final bool isOnline;
  final DateTime? onlineSince;
  final int completedOrders;
  final double completionRate;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.rating,
    required this.isOnline,
    required this.onlineSince,
    required this.completedOrders,
    required this.completionRate,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: (map['id'] ?? '').toString(),
      fullName: (map['full_name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      rating: _toDouble(map['rating']),
      isOnline: map['is_online'] == true,
      onlineSince: _toDateTime(map['online_since']),
      completedOrders: _toInt(map['completed_orders']),
      completionRate: _toDouble(map['completion_rate']),
    );
  }
}

class OrderItemModel {
  final String id;
  final String orderId;
  final String menuItemId;
  final String itemName;
  final int quantity;
  final double unitPrice;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => unitPrice * quantity;

  factory OrderItemModel.fromMap(
    Map<String, dynamic> map, {
    required String itemName,
  }) {
    return OrderItemModel(
      id: (map['id'] ?? '').toString(),
      orderId: (map['order_id'] ?? '').toString(),
      menuItemId: (map['menu_item_id'] ?? '').toString(),
      itemName: itemName,
      quantity: _toInt(map['quantity']),
      unitPrice: _toDouble(map['unit_price']),
    );
  }
}

class OrderModel {
  final String id;
  final String customerId;
  final String restaurantId;
  final String? shipperId;
  final OrderStatus status;
  final String deliveryAddress;
  final String customerPhone;
  final double distanceKm;
  final double? pickupLat;
  final double? pickupLng;
  final double? deliveryLat;
  final double? deliveryLng;
  final double shippingFee;
  final double subtotal;
  final double totalAmount;
  final int estimatedMinutes;
  final DateTime? orderedAt;
  final DateTime? pickedUpAt;
  final DateTime? completedAt;
  final RestaurantModel? restaurant;
  final UserModel? customer;
  final List<OrderItemModel> items;
  final int itemCount;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.restaurantId,
    required this.shipperId,
    required this.status,
    required this.deliveryAddress,
    required this.customerPhone,
    required this.distanceKm,
    required this.pickupLat,
    required this.pickupLng,
    required this.deliveryLat,
    required this.deliveryLng,
    required this.shippingFee,
    required this.subtotal,
    required this.totalAmount,
    required this.estimatedMinutes,
    required this.orderedAt,
    required this.pickedUpAt,
    required this.completedAt,
    required this.restaurant,
    required this.customer,
    required this.items,
    required this.itemCount,
  });

  double get earning => shippingFee;

  String get deliveryAddressDisplay {
    final normalized = deliveryAddress.trim();
    return normalized.isEmpty ? 'Khong co dia chi' : normalized;
  }

  factory OrderModel.fromMap(
    Map<String, dynamic> map, {
    RestaurantModel? restaurant,
    UserModel? customer,
    List<OrderItemModel>? items,
    int? itemCount,
  }) {
    final currentItems = items ?? const <OrderItemModel>[];
    return OrderModel(
      id: (map['id'] ?? '').toString(),
      customerId: (map['customer_id'] ?? '').toString(),
      restaurantId: (map['restaurant_id'] ?? '').toString(),
      shipperId: map['shipper_id']?.toString(),
      status: parseOrderStatus((map['status'] ?? 'pending').toString()),
      deliveryAddress: (map['delivery_address'] ?? '').toString(),
      customerPhone: (map['customer_phone'] ?? '').toString(),
      distanceKm: _toDouble(map['distance_km']),
      pickupLat: map['pickup_lat'] == null ? null : _toDouble(map['pickup_lat']),
      pickupLng: map['pickup_lng'] == null ? null : _toDouble(map['pickup_lng']),
      deliveryLat: map['delivery_lat'] == null ? null : _toDouble(map['delivery_lat']),
      deliveryLng: map['delivery_lng'] == null ? null : _toDouble(map['delivery_lng']),
      shippingFee: _toDouble(map['shipping_fee']),
      subtotal: _toDouble(map['subtotal']),
      totalAmount: _toDouble(map['total_amount']),
      estimatedMinutes: _toInt(map['estimated_minutes']),
      orderedAt: _toDateTime(map['ordered_at']),
      pickedUpAt: _toDateTime(map['picked_up_at']),
      completedAt: _toDateTime(map['completed_at']),
      restaurant: restaurant,
      customer: customer,
      items: currentItems,
      itemCount: itemCount ?? currentItems.length,
    );
  }
}

class ShipperDashboardStats {
  final bool isOnline;
  final int ordersToday;
  final double earningsToday;
  final int totalOrders;
  final Duration onlineDuration;

  const ShipperDashboardStats({
    required this.isOnline,
    required this.ordersToday,
    required this.earningsToday,
    required this.totalOrders,
    required this.onlineDuration,
  });
}

class EarningsSummary {
  final double today;
  final double week;
  final double month;
  final int totalOrders;
  final double averagePerOrder;

  const EarningsSummary({
    required this.today,
    required this.week,
    required this.month,
    required this.totalOrders,
    required this.averagePerOrder,
  });
}

class ShipperProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final double rating;
  final bool isOnline;
  final int completedOrders;
  final double completionRate;

  const ShipperProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.rating,
    required this.isOnline,
    required this.completedOrders,
    required this.completionRate,
  });
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

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
