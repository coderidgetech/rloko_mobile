import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._dataSource);

  final CategoryRemoteDataSource _dataSource;

  @override
  Future<List<CategoryEntity>> list() async {
    try {
      final list = await _dataSource.list();
      final entities = list.map((e) => e.toEntity()).toList();
      // Match web: only include categories with name and image (same as Categories.tsx)
      return entities.where((c) => c.name.isNotEmpty && c.image.isNotEmpty).toList();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<CategoryEntity> getById(String id) async {
    try {
      final dto = await _dataSource.getById(id);
      return dto.toEntity();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }
}
