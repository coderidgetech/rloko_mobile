import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class GetNewArrivalsUseCase {
  GetNewArrivalsUseCase(this._repository);

  final ProductRepository _repository;

  Future<List<ProductEntity>> call({int limit = 10}) =>
      _repository.getNewArrivals(limit: limit);
}
