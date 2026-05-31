import '../repositories/order_repository.dart';

class GetOrderTrackingUseCase {
  GetOrderTrackingUseCase(this._repo);
  final OrderRepository _repo;
  Future<List<OrderTrackingUpdateEntity>> call(String orderId) =>
      _repo.getTracking(orderId);
}
