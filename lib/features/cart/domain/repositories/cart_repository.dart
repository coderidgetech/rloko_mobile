import '../entities/cart_entity.dart';
import '../entities/cart_item_entity.dart';

abstract class CartRepository {
  Future<CartEntity> getCart();

  Future<void> addItem(CartItemEntity item);

  Future<void> updateItem(String productId, String size, int quantity);

  Future<void> removeItem(String productId, String size);

  Future<void> clearCart();
}
