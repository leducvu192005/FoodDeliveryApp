class CartItem {
  final String cartItemId;
  final int quantity;
  final Dish dish;
  final double totalPrice;

  CartItem({
    required this.cartItemId,
    required this.quantity,
    required this.dish,
    required this.totalPrice,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartItemId: json['cart_item_id'],
      quantity: json['quantity'],
      dish: Dish.fromJson(json['dish']),
      totalPrice: (json['quantity'] * json['dish']['price']).toDouble(),
    );
  }
}

class Dish {
  final int id;
  final String name;
  final double price;
  final String img;

  Dish({
    required this.id,
    required this.name,
    required this.price,
    required this.img,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
      img: json['img'],
    );
  }
}
