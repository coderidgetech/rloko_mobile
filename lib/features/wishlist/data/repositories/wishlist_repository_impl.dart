import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/wishlist_entity.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../datasources/wishlist_remote_datasource.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  WishlistRepositoryImpl(this._dataSource);

  final WishlistRemoteDataSource _dataSource;

  @override
  Future<List<WishlistEntity>> getWishlist() async {
    try {
      final list = await _dataSource.getWishlist();
      return list.map((e) => e.toEntity()).toList();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<void> addItem(String productId) async {
    try {
      await _dataSource.addItem(productId);
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<void> removeItem(String productId) async {
    try {
      await _dataSource.removeItem(productId);
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }
}
