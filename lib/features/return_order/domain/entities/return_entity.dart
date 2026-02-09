import 'package:equatable/equatable.dart';

class ReturnEntity extends Equatable {
  const ReturnEntity({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.reason,
    this.description,
    required this.status,
    required this.refundAmount,
    required this.refundStatus,
    required this.createdAt,
    this.items = const [],
  });

  final String id;
  final String orderId;
  final String orderNumber;
  final String reason;
  final String? description;
  final String status;
  final double refundAmount;
  final String refundStatus;
  final String createdAt;
  final List<ReturnItemEntity> items;

  @override
  List<Object?> get props => [id];
}

class ReturnItemEntity extends Equatable {
  const ReturnItemEntity({
    required this.productName,
    required this.size,
    required this.quantity,
    required this.price,
  });

  final String productName;
  final String size;
  final int quantity;
  final double price;

  @override
  List<Object?> get props => [productName, size, quantity];
}
