import '../../../../core/network/dio_client.dart';
import '../dto/shipping_method_dto.dart';

class ShippingRemoteDataSource {
  ShippingRemoteDataSource(this._client);

  final DioClient _client;
  dynamic get _dio => _client.dio;

  Future<List<ShippingMethodDto>> listMethods({bool activeOnly = true}) async {
    final response = await _dio.get<dynamic>(
      '/shipping/methods',
      queryParameters: {'active_only': activeOnly},
    );
    final data = response.data;
    if (data is! List) return [];
    return (data as List)
        .map((e) => ShippingMethodDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
