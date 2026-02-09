import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../dto/product_dto.dart';
import '../dto/product_list_response_dto.dart';

class ProductRemoteDataSource {
  ProductRemoteDataSource(this._client);

  final DioClient _client;
  Dio get _dio => _client.dio;

  Future<ProductListResponseDto> list({
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
    final query = <String, dynamic>{};
    if (limit != null) query['limit'] = limit;
    if (skip != null) query['skip'] = skip;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (gender != null && gender.isNotEmpty) query['gender'] = gender;
    if (onSale == true) query['on_sale'] = 'true';
    if (featured == true) query['featured'] = 'true';
    if (minPrice != null) query['min_price'] = minPrice;
    if (maxPrice != null) query['max_price'] = maxPrice;
    if (sort != null && sort.isNotEmpty) query['sort'] = sort;
    final response = await _dio.get<Map<String, dynamic>>(
      '/products',
      queryParameters: query,
    );
    final data = response.data;
    if (data == null) throw Exception('Invalid response');
    return ProductListResponseDto.fromJson(data);
  }

  Future<ProductDto> getById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/products/$id');
    final data = response.data;
    if (data == null) throw Exception('Invalid response');
    return ProductDto.fromJson(data);
  }

  Future<List<ProductDto>> getFeatured({int limit = 10}) async {
    final response = await _dio.get<List<dynamic>>(
      '/products/featured',
      queryParameters: {'limit': limit},
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductDto>> getNewArrivals({int limit = 10}) async {
    final response = await _dio.get<List<dynamic>>(
      '/products/new-arrivals',
      queryParameters: {'limit': limit},
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductDto>> getOnSale({int limit = 10}) async {
    final response = await _dio.get<List<dynamic>>(
      '/products/on-sale',
      queryParameters: {'limit': limit},
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
