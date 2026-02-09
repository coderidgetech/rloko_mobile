import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class GetProductByIdUseCase {
  GetProductByIdUseCase(this._repository);

  final ProductRepository _repository;

  Future<ProductEntity> call(String id) => _repository.getById(id);
}
