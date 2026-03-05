import 'dart:convert';
import 'dart:typed_data';

class Product {
  final int id;
  final String name;
  final String? img;
  final double price;
  final int? sellerId;
  final int? categoryId;
  final String? description;

  Product({
    required this.id,
    required this.name,
    this.img,
    required this.price,
    this.sellerId,
    this.categoryId,
    this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      img: json['img'],
      price: (json['price'] as num).toDouble(),
      sellerId: json['seller_id'] as int?,
      categoryId: json['category_id'] as int?,
      description: json['description'] as String?,
    );
  }

  /// ✅ GIẢI MÃ BASE64 → BYTES
  Uint8List? get imageBytes {
    if (img == null) return null;

    if (img!.startsWith('data:image')) {
      final base64Str = img!.split(',').last;
      return base64Decode(base64Str);
    }
    return null;
  }
}
