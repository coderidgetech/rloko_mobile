import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class GetCategoriesUseCase {
  GetCategoriesUseCase(this._repository);

  final CategoryRepository _repository;

  Future<List<CategoryEntity>> call() => _repository.list();
}
