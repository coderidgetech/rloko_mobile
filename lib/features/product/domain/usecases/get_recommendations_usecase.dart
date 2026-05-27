import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class GetRecommendationsUseCase {
  GetRecommendationsUseCase(this._repository);

  final ProductRepository _repository;

  Future<List<ProductEntity>> call(String productId, {int limit = 8}) =>
      _repository.getRecommendations(productId, limit: limit);
}
