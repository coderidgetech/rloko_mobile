part of 'wishlist_bloc.dart';

sealed class WishlistState extends Equatable {
  const WishlistState();
  @override
  List<Object?> get props => [];
}

final class WishlistInitial extends WishlistState {
  const WishlistInitial();
}

final class WishlistLoading extends WishlistState {
  const WishlistLoading();
}

final class WishlistLoaded extends WishlistState {
  const WishlistLoaded(this.items);
  final List<WishlistEntity> items;
  int get count => items.length;
  @override
  List<Object?> get props => [items];
}

final class WishlistError extends WishlistState {
  const WishlistError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
