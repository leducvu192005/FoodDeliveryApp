class DriverProfile {
  final String shipperId;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String vehicleType;
  final String licensePlate;
  final double rating;
  final bool isOnline;
  final double? currentLat;
  final double? currentLng;

  DriverProfile({
    required this.shipperId,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.licensePlate,
    required this.rating,
    required this.isOnline,
    required this.currentLat,
    required this.currentLng,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      shipperId: json['shipper_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      vehicleType: json['vehicle_type']?.toString() ?? '',
      licensePlate: json['license_plate']?.toString() ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      isOnline: json['is_online'] == true,
      currentLat: json['current_lat'] == null
          ? null
          : (json['current_lat'] as num).toDouble(),
      currentLng: json['current_lng'] == null
          ? null
          : (json['current_lng'] as num).toDouble(),
    );
  }
}
