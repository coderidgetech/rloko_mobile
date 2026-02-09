import '../entities/cart_entity.dart';
import '../entities/cart_item_entity.dart';
import '../repositories/cart_repository.dart';

class GetCartUseCase {
  GetCartUseCase(this._repo);
  final CartRepository _repo;
  Future<CartEntity> call() => _repo.getCart();
}

class AddCartItemUseCase {
  AddCartItemUseCase(this._repo);
  final CartRepository _repo;
  Future<void> call(CartItemEntity item) => _repo.addItem(item);
}

class UpdateCartItemUseCase {
  UpdateCartItemUseCase(this._repo);
  final CartRepository _repo;
  Future<void> call(String productId, String size, int quantity) =>
      _repo.updateItem(productId, size, quantity);
}

class RemoveCartItemUseCase {
  RemoveCartItemUseCase(this._repo);
  final CartRepository _repo;
  Future<void> call(String productId, String size) =>
      _repo.removeItem(productId, size);
}

class ClearCartUseCase {
  ClearCartUseCase(this._repo);
  final CartRepository _repo;
  Future<void> call() => _repo.clearCart();
}
