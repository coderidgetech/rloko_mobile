import '../entities/wishlist_entity.dart';

abstract class WishlistRepository {
  Future<List<WishlistEntity>> getWishlist();

  Future<void> addItem(String productId);

  Future<void> removeItem(String productId);
}
