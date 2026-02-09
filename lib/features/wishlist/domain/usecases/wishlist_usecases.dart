import '../entities/wishlist_entity.dart';
import '../repositories/wishlist_repository.dart';

class GetWishlistUseCase {
  GetWishlistUseCase(this._repo);
  final WishlistRepository _repo;
  Future<List<WishlistEntity>> call() => _repo.getWishlist();
}

class AddWishlistItemUseCase {
  AddWishlistItemUseCase(this._repo);
  final WishlistRepository _repo;
  Future<void> call(String productId) => _repo.addItem(productId);
}

class RemoveWishlistItemUseCase {
  RemoveWishlistItemUseCase(this._repo);
  final WishlistRepository _repo;
  Future<void> call(String productId) => _repo.removeItem(productId);
}
