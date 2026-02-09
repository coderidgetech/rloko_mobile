import 'package:equatable/equatable.dart';

import 'product_entity.dart';

class ProductListResult extends Equatable {
  const ProductListResult({
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
