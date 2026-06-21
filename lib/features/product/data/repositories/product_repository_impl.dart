import 'dart:async';

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_list_result.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_datasource.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._dataSource, this._localDataSource);

  final ProductRemoteDataSource _dataSource;
  final ProductLocalDataSource _localDataSource;

  @override
  Future<ProductListResult> list({
    int? limit,
    int? skip,
    String? category,
    String? gender,
    bool? onSale,
    bool? featured,
    bool? newArrival,
    bool? gift,
    double? minPrice,
    double? maxPrice,
    String? sort,
    String? search,
  }) async {
    try {
      final dto = await _dataSource.list(
        limit: limit,
        skip: skip,
        category: category,
        gender: gender,
        onSale: onSale,
        featured: featured,
        newArrival: newArrival,
        gift: gift,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sort: sort,
        search: search,
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
  Future<List<ProductEntity>> getVariants(String id) async {
    try {
      final dtos = await _dataSource.getVariants(id);
      return dtos.map((e) => e.toEntity()).toList();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<List<ProductEntity>> getFeatured({int limit = 10}) async {
    try {
      final list = await _dataSource.getFeatured(limit: limit);
      unawaited(_localDataSource.cacheSection('featured', list.map((e) => e.toJson()).toList()));
      return list.map((e) => e.toEntity()).toList();
    } on DioException catch (e) {
      final cached = _localDataSource.getCachedSection('featured');
      if (cached != null && cached.isNotEmpty) return cached.map((e) => e.toEntity()).toList();
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<List<ProductEntity>> getNewArrivals({int limit = 10}) async {
    try {
      final list = await _dataSource.getNewArrivals(limit: limit);
      unawaited(_localDataSource.cacheSection('new_arrivals', list.map((e) => e.toJson()).toList()));
      return list.map((e) => e.toEntity()).toList();
    } on DioException catch (e) {
      final cached = _localDataSource.getCachedSection('new_arrivals');
      if (cached != null && cached.isNotEmpty) return cached.map((e) => e.toEntity()).toList();
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<List<ProductEntity>> getOnSale({int limit = 10}) async {
    try {
      final list = await _dataSource.getOnSale(limit: limit);
      unawaited(_localDataSource.cacheSection('on_sale', list.map((e) => e.toJson()).toList()));
      return list.map((e) => e.toEntity()).toList();
    } on DioException catch (e) {
      final cached = _localDataSource.getCachedSection('on_sale');
      if (cached != null && cached.isNotEmpty) return cached.map((e) => e.toEntity()).toList();
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<List<ProductEntity>> getRecommendations(String productId, {int limit = 8}) async {
    try {
      final list = await _dataSource.getRecommendations(productId, limit: limit);
      return list.map((e) => e.toEntity()).toList();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }
}
