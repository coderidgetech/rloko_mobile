import 'package:equatable/equatable.dart';

class CartItemEntity extends Equatable {
  const CartItemEntity({
    required this.productId,
    required this.productName,
    required this.image,
    required this.price,
    this.priceInr,
    required this.size,
    required this.quantity,
    this.isGift,
    this.giftWrapColor,
    this.giftMessage,
  });

  final String productId;
  final String productName;
  final String image;
  final double price;
  final double? priceInr;
  final String size;
  final int quantity;
  final bool? isGift;
  final String? giftWrapColor;
  final String? giftMessage;

  @override
  List<Object?> get props => [productId, size];
}
