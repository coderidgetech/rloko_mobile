import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

/// Fetches the color-variant siblings of a product (same variant_group_id).
class GetProductVariantsUseCase {
  GetProductVariantsUseCase(this._repository);

  final ProductRepository _repository;

  Future<List<ProductEntity>> call(String id) => _repository.getVariants(id);
}
