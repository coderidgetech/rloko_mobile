import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class GetOnSaleProductsUseCase {
  GetOnSaleProductsUseCase(this._repository);

  final ProductRepository _repository;

  Future<List<ProductEntity>> call({int limit = 10}) =>
      _repository.getOnSale(limit: limit);
}
