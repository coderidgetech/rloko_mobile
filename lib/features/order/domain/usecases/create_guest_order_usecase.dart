import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class CreateGuestOrderUseCase {
  CreateGuestOrderUseCase(this._repo);
  final OrderRepository _repo;
  Future<OrderEntity> call({
    required String guestEmail,
    required String guestName,
    required List<OrderItemEntity> items,
    required ShippingInfoEntity shippingInfo,
    String? promotionCode,
  }) =>
      _repo.createGuest(
        guestEmail: guestEmail,
        guestName: guestName,
        items: items,
        shippingInfo: shippingInfo,
        promotionCode: promotionCode,
      );
}
