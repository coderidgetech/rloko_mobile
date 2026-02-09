import '../entities/category_entity.dart';

abstract class CategoryRepository {
  Future<List<CategoryEntity>> list();

  Future<CategoryEntity> getById(String id);
}
