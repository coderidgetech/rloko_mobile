import '../../domain/entities/wishlist_entity.dart';

/// Backend GET /wishlist returns a list of Product objects, not wishlist rows.
/// This DTO parses either a product map (id -> productId, name, images[0], price)
/// or a legacy wishlist row (id, user_id, product_id, created_at).
class WishlistDto {
  WishlistDto({
    required this.id,
    required this.userId,
    required this.productId,
    required this.createdAt,
    this.productName,
    this.productImage,
    this.productPrice,
  });

  /// From product JSON (backend returns []Product).
  factory WishlistDto.fromProductJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final images = json['images'];
    final image = images is List && images.isNotEmpty
        ? images.first.toString()
        : '';
    final price = (json['price'] is num)
        ? (json['price'] as num).toDouble()
        : 0.0;
    return WishlistDto(
      id: '',
      userId: '',
      productId: id,
      createdAt: '',
      productName: json['name'] as String? ?? '',
      productImage: image,
      productPrice: price,
    );
  }

  factory WishlistDto.fromJson(Map<String, dynamic> json) {
    final productId = json['product_id']?.toString() ?? json['id']?.toString() ?? '';
    final images = json['images'];
    final image = images is List && images.isNotEmpty
        ? images.first.toString()
        : json['image'] as String? ?? '';
    final price = (json['price'] is num)
        ? (json['price'] as num).toDouble()
        : null;
    return WishlistDto(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      productId: productId,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toIso8601String() ?? ''
          : '',
      productName: json['product_name'] as String? ?? json['name'] as String?,
      productImage: image.isNotEmpty ? image : null,
      productPrice: price,
    );
  }

  final String id;
  final String userId;
  final String productId;
  final String createdAt;
  final String? productName;
  final String? productImage;
  final double? productPrice;

  WishlistEntity toEntity() => WishlistEntity(
        id: id,
        userId: userId,
        productId: productId,
        createdAt: createdAt,
        productName: productName,
        productImage: productImage,
        productPrice: productPrice,
      );
}
