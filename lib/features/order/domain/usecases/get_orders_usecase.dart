import '../repositories/order_repository.dart';

class GetOrdersUseCase {
  GetOrdersUseCase(this._repo);
  final OrderRepository _repo;
  Future<OrderListResult> call({int? limit, int? skip, String? status}) =>
      _repo.list(limit: limit, skip: skip, status: status);
}
