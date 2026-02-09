import '../../domain/entities/return_entity.dart';

String _str(dynamic v) => v?.toString() ?? '';
String _date(dynamic v) =>
    v != null ? (DateTime.tryParse(v.toString())?.toIso8601String() ?? '') : '';

class ReturnDto {
  ReturnDto({
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

  factory ReturnDto.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>?;
    final items = itemsList
            ?.map((e) => ReturnItemDto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return ReturnDto(
      id: _str(json['id']),
      orderId: _str(json['order_id']),
      orderNumber: json['order_number'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'requested',
      refundAmount: (json['refund_amount'] as num?)?.toDouble() ?? 0,
      refundStatus: json['refund_status'] as String? ?? 'pending',
      createdAt: _date(json['created_at']),
      items: items,
    );
  }

  final String id;
  final String orderId;
  final String orderNumber;
  final String reason;
  final String? description;
  final String status;
  final double refundAmount;
  final String refundStatus;
  final String createdAt;
  final List<ReturnItemDto> items;

  ReturnEntity toEntity() => ReturnEntity(
        id: id,
        orderId: orderId,
        orderNumber: orderNumber,
        reason: reason,
        description: description,
        status: status,
        refundAmount: refundAmount,
        refundStatus: refundStatus,
        createdAt: createdAt,
        items: items.map((e) => e.toEntity()).toList(),
      );
}

class ReturnItemDto {
  ReturnItemDto({
    required this.productName,
    required this.size,
    required this.quantity,
    required this.price,
  });

  factory ReturnItemDto.fromJson(Map<String, dynamic> json) {
    return ReturnItemDto(
      productName: json['product_name'] as String? ?? '',
      size: json['size'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  final String productName;
  final String size;
  final int quantity;
  final double price;

  ReturnItemEntity toEntity() => ReturnItemEntity(
        productName: productName,
        size: size,
        quantity: quantity,
        price: price,
      );
}
