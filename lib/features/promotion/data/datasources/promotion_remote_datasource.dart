import '../../../../core/network/dio_client.dart';
import '../dto/promotion_dto.dart';

class PromotionRemoteDataSource {
  PromotionRemoteDataSource(this._client);

  final DioClient _client;
  dynamic get _dio => _client.dio;

  Future<List<PromotionDto>> list({bool activeOnly = true}) async {
    final response = await _dio.get<dynamic>(
      '/promotions',
      queryParameters: {'active_only': activeOnly},
    );
    final data = response.data;
    if (data is! List) return [];
    return (data as List)
        .map((e) => PromotionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> validate(String code, double subtotal) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/promotions/validate',
      data: {'code': code, 'subtotal': subtotal},
    );
    final data = response.data;
    if (data == null) throw Exception('Invalid response');
    return data;
  }
}
