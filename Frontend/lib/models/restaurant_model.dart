class RestaurantModel {
  final String id;
  final String name;
  final String address;
  final String phone;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
  });

  factory RestaurantModel.fromMap(Map<String, dynamic> map) {
    return RestaurantModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
    );
  }
}
