import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../dto/wishlist_dto.dart';

class WishlistRemoteDataSource {
  WishlistRemoteDataSource(this._client);

  final DioClient _client;
  Dio get _dio => _client.dio;

  /// Backend GET /wishlist returns a list of Product objects.
  Future<List<WishlistDto>> getWishlist() async {
    final response = await _dio.get<List<dynamic>>('/wishlist');
    final data = response.data;
    if (data == null) return [];
    return data
        .map((e) => WishlistDto.fromProductJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addItem(String productId) async {
    await _dio.post<dynamic>(
      '/wishlist/items',
      data: {'product_id': productId},
    );
  }

  Future<void> removeItem(String productId) async {
    await _dio.delete<dynamic>('/wishlist/items/$productId');
  }
}
