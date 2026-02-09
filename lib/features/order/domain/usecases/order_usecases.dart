import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class GetOrdersUseCase {
  GetOrdersUseCase(this._repo);
  final OrderRepository _repo;
  Future<OrderListResult> call({int? limit, int? skip, String? status}) =>
      _repo.list(limit: limit, skip: skip, status: status);
}

class GetOrderByIdUseCase {
  GetOrderByIdUseCase(this._repo);
  final OrderRepository _repo;
  Future<OrderEntity> call(String id) => _repo.getById(id);
}

class GetOrderTrackingUseCase {
  GetOrderTrackingUseCase(this._repo);
  final OrderRepository _repo;
  Future<List<OrderTrackingUpdateEntity>> call(String orderId) =>
      _repo.getTracking(orderId);
}

class CancelOrderUseCase {
  CancelOrderUseCase(this._repo);
  final OrderRepository _repo;
  Future<void> call(String orderId, {String? reason}) =>
      _repo.cancel(orderId, reason: reason);
}

class CreateOrderUseCase {
  CreateOrderUseCase(this._repo);
  final OrderRepository _repo;
  Future<OrderEntity> call({
    required List<OrderItemEntity> items,
    required ShippingInfoEntity shippingInfo,
    required String paymentMethod,
    Map<String, dynamic>? paymentInfo,
    String? promotionCode,
  }) =>
      _repo.create(
        items: items,
        shippingInfo: shippingInfo,
        paymentMethod: paymentMethod,
        paymentInfo: paymentInfo,
        promotionCode: promotionCode,
      );
}
