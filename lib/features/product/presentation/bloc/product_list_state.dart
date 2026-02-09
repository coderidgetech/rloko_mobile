part of 'product_list_bloc.dart';

sealed class ProductListState extends Equatable {
  const ProductListState();

  @override
  List<Object?> get props => [];
}

final class ProductListInitial extends ProductListState {
  const ProductListInitial();
}

final class ProductListLoading extends ProductListState {
  const ProductListLoading();
}

final class ProductListLoaded extends ProductListState {
  const ProductListLoaded({
    required this.products,
    required this.total,
    required this.limit,
    required this.skip,
  });

  final List<ProductEntity> products;
  final int total;
  final int limit;
  final int skip;

  @override
  List<Object?> get props => [products, total, limit, skip];
}

final class ProductListError extends ProductListState {
  const ProductListError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class ProductListHomeLoading extends ProductListState {
  const ProductListHomeLoading();
}

final class ProductListHomeLoaded extends ProductListState {
  const ProductListHomeLoaded({
    required this.featured,
    required this.newArrivals,
    required this.sale,
  });

  final List<ProductEntity> featured;
  final List<ProductEntity> newArrivals;
  final List<ProductEntity> sale;

  @override
  List<Object?> get props => [featured.length, newArrivals.length, sale.length];
}
