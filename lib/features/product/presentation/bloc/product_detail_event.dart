part of 'product_detail_bloc.dart';

sealed class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();

  @override
  List<Object?> get props => [];
}

final class ProductDetailLoadRequested extends ProductDetailEvent {
  const ProductDetailLoadRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
