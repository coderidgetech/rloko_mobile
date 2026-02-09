import 'package:equatable/equatable.dart';

class WishlistEntity extends Equatable {
  const WishlistEntity({
    required this.id,
    required this.userId,
    required this.productId,
    required this.createdAt,
    this.productName,
    this.productImage,
    this.productPrice,
  });

  final String id;
  final String userId;
  final String productId;
  final String createdAt;
  /// From product when backend returns products list (GET /wishlist).
  final String? productName;
  final String? productImage;
  final double? productPrice;

  @override
  List<Object?> get props => [id, productId];
}
