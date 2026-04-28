import '../../domain/entities/calculate_shipping_params.dart';
import '../../../../core/network/dio_client.dart';
import '../dto/shipping_method_dto.dart';

class ShippingRemoteDataSource {
  ShippingRemoteDataSource(this._client);

  final DioClient _client;
  dynamic get _dio => _client.dio;

  Future<List<ShippingMethodDto>> calculate(CalculateShippingParams params) async {
    final response = await _dio.post<dynamic>('/shipping/calculate', data: params.toJson());
    final data = response.data;
    if (data is Map && data['methods'] is List) {
      return (data['methods'] as List<dynamic>)
          .map((e) => ShippingMethodDto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is List) {
      return data
          .map((e) => ShippingMethodDto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<ShippingMethodDto>> listMethods({bool activeOnly = true}) async {
    final response = await _dio.get<dynamic>(
      '/shipping/methods',
      queryParameters: {'active_only': activeOnly},
    );
    final data = response.data;
    if (data is! List) return [];
    return data
        .map((e) => ShippingMethodDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
