import '../entities/wishlist_entity.dart';
import '../repositories/wishlist_repository.dart';

class GetWishlistUseCase {
  GetWishlistUseCase(this._repo);
  final WishlistRepository _repo;
  Future<List<WishlistEntity>> call() => _repo.getWishlist();
}
