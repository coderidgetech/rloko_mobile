import 'package:equatable/equatable.dart';

class OrderItemEntity extends Equatable {
  const OrderItemEntity({
    required this.productId,
    required this.productName,
    required this.image,
    required this.price,
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
  final String size;
  final int quantity;
  final bool? isGift;
  final String? giftWrapColor;
  final String? giftMessage;

  @override
  List<Object?> get props => [productId, size];
}

class ShippingInfoEntity extends Equatable {
  const ShippingInfoEntity({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  @override
  List<Object?> get props => [email, address];
}

class OrderEntity extends Equatable {
  const OrderEntity({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.items,
    required this.shippingInfo,
    required this.subtotal,
    required this.discount,
    required this.shippingCost,
    this.giftPackingCharge,
    required this.tax,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    this.trackingNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String orderNumber;
  final String userId;
  final List<OrderItemEntity> items;
  final ShippingInfoEntity shippingInfo;
  final double subtotal;
  final double discount;
  final double shippingCost;
  final double? giftPackingCharge;
  final double tax;
  final double total;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String? trackingNumber;
  final String createdAt;
  final String updatedAt;

  @override
  List<Object?> get props => [id, orderNumber];
}
