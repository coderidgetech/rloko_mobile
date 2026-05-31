import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

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
