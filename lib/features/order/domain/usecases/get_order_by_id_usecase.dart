import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class GetOrderByIdUseCase {
  GetOrderByIdUseCase(this._repo);
  final OrderRepository _repo;
  Future<OrderEntity> call(String id) => _repo.getById(id);
}
