import '../../domain/entities/cart_entity.dart';
import '../../domain/entities/cart_item_entity.dart';

class CartItemDto {
  CartItemDto({
    required this.productId,
    required this.productName,
    required this.image,
    required this.price,
    this.priceInr,
    required this.size,
    required this.quantity,
  });

  factory CartItemDto.fromJson(Map<String, dynamic> json) {
    return CartItemDto(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name'] as String? ?? '',
      image: json['image'] as String? ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      priceInr: json['price_inr'] != null
          ? (json['price_inr'] as num).toDouble()
          : null,
      size: json['size'] as String? ?? '',
      quantity: json['quantity'] is int ? json['quantity'] as int : 0,
    );
  }

  final String productId;
  final String productName;
  final String image;
  final double price;
  final double? priceInr;
  final String size;
  final int quantity;

  CartItemEntity toEntity() => CartItemEntity(
        productId: productId,
        productName: productName,
        image: image,
        price: price,
        priceInr: priceInr,
        size: size,
        quantity: quantity,
      );

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'image': image,
        'price': price,
        if (priceInr != null) 'price_inr': priceInr,
        'size': size,
        'quantity': quantity,
      };
}

class CartDto {
  CartDto({
    required this.id,
    required this.userId,
    required this.items,
    required this.updatedAt,
  });

  factory CartDto.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final items = itemsRaw is List
        ? (itemsRaw)
            .map((e) => CartItemDto.fromJson(e as Map<String, dynamic>))
            .toList()
        : <CartItemDto>[];
    return CartDto(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      items: items,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toIso8601String() ?? ''
          : '',
    );
  }

  final String id;
  final String userId;
  final List<CartItemDto> items;
  final String updatedAt;

  CartEntity toEntity() => CartEntity(
        id: id,
        userId: userId,
        items: items.map((e) => e.toEntity()).toList(),
        updatedAt: updatedAt,
      );
}
