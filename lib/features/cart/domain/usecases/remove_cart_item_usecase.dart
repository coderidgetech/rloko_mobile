import '../repositories/cart_repository.dart';

class RemoveCartItemUseCase {
  RemoveCartItemUseCase(this._repo);
  final CartRepository _repo;
  Future<void> call(String productId, String size) =>
      _repo.removeItem(productId, size);
}
