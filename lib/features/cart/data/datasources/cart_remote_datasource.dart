import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../dto/cart_dto.dart';

class CartRemoteDataSource {
  CartRemoteDataSource(this._client);

  final DioClient _client;
  Dio get _dio => _client.dio;

  Future<CartDto> getCart() async {
    final response = await _dio.get<Map<String, dynamic>>('/cart');
    final data = response.data;
    if (data == null) throw Exception('Invalid response');
    return CartDto.fromJson(data);
  }

  Future<void> addItem(CartItemDto item) async {
    await _dio.post<dynamic>('/cart/items', data: item.toJson());
  }

  Future<void> updateItem(String productId, String size, int quantity) async {
    await _dio.put<dynamic>(
      '/cart/items/$productId',
      data: {'quantity': quantity, 'size': size},
    );
  }

  Future<void> removeItem(String productId, String size) async {
    await _dio.delete<dynamic>(
      '/cart/items/$productId',
      data: {'size': size},
    );
  }

  Future<void> clearCart() async {
    await _dio.delete<dynamic>('/cart');
  }
}
