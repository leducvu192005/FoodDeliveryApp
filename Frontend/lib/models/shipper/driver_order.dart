class DriverOrder {
  final String id;
  final String customerName;
  final String customerPhone;
  final String restaurantName;
  final String pickupAddress;
  final String deliveryAddress;
  final double totalPrice;
  final double shippingFee;
  final String status;
  final DateTime createdAt;

  DriverOrder({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.restaurantName,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.totalPrice,
    required this.shippingFee,
    required this.status,
    required this.createdAt,
  });

  factory DriverOrder.fromJson(Map<String, dynamic> json) {
    return DriverOrder(
      id: json['id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      restaurantName: json['restaurant_name']?.toString() ?? '',
      pickupAddress: json['pickup_address']?.toString() ?? '',
      deliveryAddress: json['delivery_address']?.toString() ?? '',
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      shippingFee: (json['shipping_fee'] ?? 0).toDouble(),
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
