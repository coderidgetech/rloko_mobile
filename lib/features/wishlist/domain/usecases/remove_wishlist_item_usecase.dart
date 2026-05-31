import '../repositories/wishlist_repository.dart';

class RemoveWishlistItemUseCase {
  RemoveWishlistItemUseCase(this._repo);
  final WishlistRepository _repo;
  Future<void> call(String productId) => _repo.removeItem(productId);
}
