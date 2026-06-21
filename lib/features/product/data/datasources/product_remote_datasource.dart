import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/region/app_region.dart';
import '../../../../core/region/region_repository.dart';
import '../dto/product_dto.dart';
import '../dto/product_list_response_dto.dart';

class ProductRemoteDataSource {
  ProductRemoteDataSource(this._client, this._regionRepository);

  final DioClient _client;
  final RegionRepository _regionRepository;
  Dio get _dio => _client.dio;

  String get _marketCode => _regionRepository.getRegionSync().marketCode;

  Future<ProductListResponseDto> list({
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
    final query = <String, dynamic>{};
    if (limit != null) query['limit'] = limit;
    if (skip != null) query['skip'] = skip;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (gender != null && gender.isNotEmpty) query['gender'] = gender;
    if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
    query['market'] = _marketCode;
    if (onSale == true) query['on_sale'] = 'true';
    if (featured == true) query['featured'] = 'true';
    if (newArrival == true) query['new_arrival'] = 'true';
    if (gift == true) query['gift'] = 'true';
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
    final response = await _dio.get<Map<String, dynamic>>(
      '/products/$id',
      queryParameters: {'market': _marketCode},
    );
    final data = response.data;
    if (data == null) throw Exception('Invalid response');
    return ProductDto.fromJson(data);
  }

  /// Color-variant siblings (same variant_group_id) for the PDP color switcher.
  Future<List<ProductDto>> getVariants(String id) async {
    final response = await _dio.get<dynamic>(
      '/products/$id/variants',
      queryParameters: {'market': _marketCode},
    );
    final data = response.data;
    final raw = data is Map ? data['variants'] ?? data['products'] : data;
    if (raw is! List) return [];
    return raw
        .map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductDto>> getFeatured({int limit = 10}) async {
    final response = await _dio.get<List<dynamic>>(
      '/products/featured',
      queryParameters: {'limit': limit, 'market': _marketCode},
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
      queryParameters: {'limit': limit, 'market': _marketCode},
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
      queryParameters: {'limit': limit, 'market': _marketCode},
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductDto>> getRecommendations(String productId, {int limit = 8}) async {
    final response = await _dio.get<dynamic>(
      '/products/$productId/recommendations',
      queryParameters: {'limit': limit, 'market': _marketCode},
    );
    final data = response.data;
    if (data is! Map) return [];
    final raw = data['products'];
    if (raw is! List) return [];
    return raw
        .map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
