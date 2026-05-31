import '../repositories/wishlist_repository.dart';

class AddWishlistItemUseCase {
  AddWishlistItemUseCase(this._repo);
  final WishlistRepository _repo;
  Future<void> call(String productId) => _repo.addItem(productId);
}
