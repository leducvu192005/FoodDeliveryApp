class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? img; // thay imageUrl thành img
  final int categoryId;
  final String? group;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.img,
    required this.categoryId,
    this.group,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      img: json['img'],
      categoryId: json['category_id'] ?? 0,
      group: json['group'],
    );
  }
}
