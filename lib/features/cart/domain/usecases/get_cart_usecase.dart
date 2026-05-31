import '../entities/cart_entity.dart';
import '../repositories/cart_repository.dart';

class GetCartUseCase {
  GetCartUseCase(this._repo);
  final CartRepository _repo;
  Future<CartEntity> call() => _repo.getCart();
}
