import '../entities/cart_item_entity.dart';
import '../repositories/cart_repository.dart';

class AddCartItemUseCase {
  AddCartItemUseCase(this._repo);
  final CartRepository _repo;
  Future<void> call(CartItemEntity item) => _repo.addItem(item);
}
