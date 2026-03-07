class DriverEarnings {
  final double totalEarnings;
  final int completedOrders;

  DriverEarnings({
    required this.totalEarnings,
    required this.completedOrders,
  });

  factory DriverEarnings.fromJson(Map<String, dynamic> json) {
    return DriverEarnings(
      totalEarnings: (json['total_earnings'] ?? 0).toDouble(),
      completedOrders: (json['completed_orders'] ?? 0) as int,
    );
  }
}
