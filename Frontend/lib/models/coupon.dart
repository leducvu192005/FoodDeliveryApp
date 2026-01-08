class Coupon {
  final int id;
  final String code;
  final String? title;
  final String? description;
  final String discountType;
  final double discountValue;
  final double? minOrderValue;
  Coupon({
    required this.id,
    required this.code,
    this.title,
    this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
  });
  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'],
      code: json['code'],
      title: json['title'],
      description: json['description'],
      discountType: json['discount_type'],
      discountValue: (json['discount_value'] as num).toDouble(),
      minOrderValue: json['min_order_value'] != null
          ? (json['min_order_value'] as num).toDouble()
          : null,
    );
  }
}
