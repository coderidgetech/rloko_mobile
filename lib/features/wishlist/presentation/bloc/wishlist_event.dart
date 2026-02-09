part of 'wishlist_bloc.dart';

sealed class WishlistEvent extends Equatable {
  const WishlistEvent();
  @override
  List<Object?> get props => [];
}

final class WishlistLoadRequested extends WishlistEvent {
  const WishlistLoadRequested();
}

final class WishlistAddItemRequested extends WishlistEvent {
  const WishlistAddItemRequested(
    this.productId, {
    this.productName,
    this.productImage,
    this.productPrice,
  });
  final String productId;
  final String? productName;
  final String? productImage;
  final double? productPrice;
  @override
  List<Object?> get props => [productId, productName, productImage, productPrice];
}

final class WishlistRemoveItemRequested extends WishlistEvent {
  const WishlistRemoveItemRequested(this.productId);
  final String productId;
  @override
  List<Object?> get props => [productId];
}

/// After login: merge in-memory guest wishlist to API, then load.
final class WishlistMergeGuestRequested extends WishlistEvent {
  const WishlistMergeGuestRequested();
}
