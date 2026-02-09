part of 'cart_bloc.dart';

sealed class CartState extends Equatable {
  const CartState();
  @override
  List<Object?> get props => [];
}

final class CartInitial extends CartState {
  const CartInitial();
}

final class CartLoading extends CartState {
  const CartLoading();
}

final class CartLoaded extends CartState {
  const CartLoaded(this.cart);
  final CartEntity cart;
  @override
  List<Object?> get props => [cart];
}

final class CartError extends CartState {
  const CartError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
