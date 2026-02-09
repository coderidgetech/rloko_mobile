import '../../../../core/network/dio_client.dart';
import '../dto/return_dto.dart';

class ReturnRemoteDataSource {
  ReturnRemoteDataSource(this._client);

  final DioClient _client;
  dynamic get _dio => _client.dio;

  Future<ReturnListResponse> list({int limit = 20, int skip = 0}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/returns',
      queryParameters: {'limit': limit, 'skip': skip},
    );
    final data = response.data;
    if (data == null) return ReturnListResponse(returns: [], total: 0);
    final list = data['returns'] as List<dynamic>? ?? [];
    final total = (data['total'] as num?)?.toInt() ?? 0;
    final returns = list
        .map((e) => ReturnDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return ReturnListResponse(returns: returns, total: total);
  }

  Future<ReturnDto> getById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/returns/$id');
    final data = response.data;
    if (data == null) throw Exception('Invalid response');
    return ReturnDto.fromJson(data);
  }
}

class ReturnListResponse {
  ReturnListResponse({required this.returns, required this.total});
  final List<ReturnDto> returns;
  final int total;
}
