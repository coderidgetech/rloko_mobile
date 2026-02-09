import '../entities/product_list_result.dart';
import '../repositories/product_repository.dart';

class GetProductListUseCase {
  GetProductListUseCase(this._repository);

  final ProductRepository _repository;

  Future<ProductListResult> call({
    int? limit,
    int? skip,
    String? category,
    String? gender,
    bool? onSale,
    bool? featured,
    double? minPrice,
    double? maxPrice,
    String? sort,
  }) =>
      _repository.list(
        limit: limit,
        skip: skip,
        category: category,
        gender: gender,
        onSale: onSale,
        featured: featured,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sort: sort,
      );
}
