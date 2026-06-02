import '../entities/order_entity.dart';

abstract class OrderRepository {
  Future<OrderListResult> list({int? limit, int? skip, String? status});

  Future<OrderEntity> getById(String id);

  Future<OrderEntity> getByOrderNumber(String orderNumber);

  Future<List<OrderTrackingUpdateEntity>> getTracking(String orderId);

  Future<void> cancel(String orderId, {String? reason});

  Future<OrderEntity> create({
    required List<OrderItemEntity> items,
    required ShippingInfoEntity shippingInfo,
    required String paymentMethod,
    Map<String, dynamic>? paymentInfo,
    String? promotionCode,
    double giftPackingCharge = 0,
  });

  Future<OrderEntity> createGuest({
    required String guestEmail,
    required String guestName,
    required List<OrderItemEntity> items,
    required ShippingInfoEntity shippingInfo,
    String? promotionCode,
  });
}

class OrderListResult {
  const OrderListResult({required this.orders, required this.total});

  final List<OrderEntity> orders;
  final int total;
}

class OrderTrackingUpdateEntity {
  const OrderTrackingUpdateEntity({
    required this.status,
    this.description,
    this.location,
    required this.createdAt,
  });

  final String status;
  final String? description;
  final String? location;
  final String createdAt;
}
