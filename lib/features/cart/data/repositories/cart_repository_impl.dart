import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_datasource.dart';
import '../dto/cart_dto.dart';

class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._dataSource);

  final CartRemoteDataSource _dataSource;

  @override
  Future<CartEntity> getCart() async {
    try {
      final dto = await _dataSource.getCart();
      return dto.toEntity();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<void> addItem(CartItemEntity item) async {
    try {
      await _dataSource.addItem(CartItemDto(
        productId: item.productId,
        productName: item.productName,
        image: item.image,
        price: item.price,
        priceInr: item.priceInr,
        size: item.size,
        quantity: item.quantity,
      ));
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<void> updateItem(String productId, String size, int quantity) async {
    try {
      await _dataSource.updateItem(productId, size, quantity);
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<void> removeItem(String productId, String size) async {
    try {
      await _dataSource.removeItem(productId, size);
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<void> clearCart() async {
    try {
      await _dataSource.clearCart();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }
}
