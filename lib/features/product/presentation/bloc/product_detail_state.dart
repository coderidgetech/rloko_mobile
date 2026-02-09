part of 'product_detail_bloc.dart';

sealed class ProductDetailState extends Equatable {
  const ProductDetailState();

  @override
  List<Object?> get props => [];
}

final class ProductDetailInitial extends ProductDetailState {
  const ProductDetailInitial();
}

final class ProductDetailLoading extends ProductDetailState {
  const ProductDetailLoading();
}

final class ProductDetailLoaded extends ProductDetailState {
  const ProductDetailLoaded(this.product);

  final ProductEntity product;

  @override
  List<Object?> get props => [product];
}

final class ProductDetailError extends ProductDetailState {
  const ProductDetailError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
