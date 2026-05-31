import '../repositories/cart_repository.dart';

class UpdateCartItemUseCase {
  UpdateCartItemUseCase(this._repo);
  final CartRepository _repo;
  Future<void> call(String productId, String size, int quantity) =>
      _repo.updateItem(productId, size, quantity);
}
