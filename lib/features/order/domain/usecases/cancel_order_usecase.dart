import '../repositories/order_repository.dart';

class CancelOrderUseCase {
  CancelOrderUseCase(this._repo);
  final OrderRepository _repo;
  Future<void> call(String orderId, {String? reason}) =>
      _repo.cancel(orderId, reason: reason);
}
