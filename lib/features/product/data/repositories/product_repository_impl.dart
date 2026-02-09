import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_list_result.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._dataSource);

  final ProductRemoteDataSource _dataSource;

  @override
  Future<ProductListResult> list({
    int? limit,
    int? skip,
    String? category,
    String? gender,
    bool? onSale,
    bool? featured,
    double? minPrice,
    double? maxPrice,
    String? sort,
  }) async {
    try {
      final dto = await _dataSource.list(
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
      return ProductListResult(
        products: dto.products.map((e) => e.toEntity()).toList(),
        total: dto.total,
        limit: dto.limit,
        skip: dto.skip,
      );
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<ProductEntity> getById(String id) async {
    try {
      final dto = await _dataSource.getById(id);
      return dto.toEntity();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<List<ProductEntity>> getFeatured({int limit = 10}) async {
    try {
      final list = await _dataSource.getFeatured(limit: limit);
      return list.map((e) => e.toEntity()).toList();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<List<ProductEntity>> getNewArrivals({int limit = 10}) async {
    try {
      final list = await _dataSource.getNewArrivals(limit: limit);
      return list.map((e) => e.toEntity()).toList();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<List<ProductEntity>> getOnSale({int limit = 10}) async {
    try {
      final list = await _dataSource.getOnSale(limit: limit);
      return list.map((e) => e.toEntity()).toList();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }
}
