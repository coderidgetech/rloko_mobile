part of 'cart_bloc.dart';

sealed class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

final class CartLoadRequested extends CartEvent {
  const CartLoadRequested();
}

final class CartAddItemRequested extends CartEvent {
  const CartAddItemRequested(this.item);
  final CartItemEntity item;
  @override
  List<Object?> get props => [item];
}

final class CartUpdateItemRequested extends CartEvent {
  const CartUpdateItemRequested(this.productId, this.size, this.quantity);
  final String productId;
  final String size;
  final int quantity;
  @override
  List<Object?> get props => [productId, size, quantity];
}

final class CartRemoveItemRequested extends CartEvent {
  const CartRemoveItemRequested(this.productId, this.size);
  final String productId;
  final String size;
  @override
  List<Object?> get props => [productId, size];
}

final class CartClearRequested extends CartEvent {
  const CartClearRequested();
}

/// After login: merge guest cart from local storage to API, then load cart.
final class CartMergeGuestCartRequested extends CartEvent {
  const CartMergeGuestCartRequested();
}
