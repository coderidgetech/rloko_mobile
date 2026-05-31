import '../../../../core/network/dio_client.dart';
import '../dto/inspiration_video_dto.dart';

class VideoRemoteDataSource {
  VideoRemoteDataSource(this._client);

  final DioClient _client;
  dynamic get _dio => _client.dio;

  Future<List<InspirationVideoDto>> list({
    int? limit,
    int? skip,
    String? category,
    bool? featured,
  }) async {
    final query = <String, dynamic>{};
    if (limit != null) query['limit'] = limit;
    if (skip != null) query['skip'] = skip;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (featured == true) query['featured'] = 'true';
    final response = await _dio.get<Map<String, dynamic>>(
      '/videos',
      queryParameters: query.isNotEmpty ? query : null,
    );
    final data = response.data;
    if (data == null) throw Exception('Invalid response');
    final videosRaw = data['videos'];
    if (videosRaw is! List) return [];
    return (videosRaw)
        .map((e) => InspirationVideoDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<InspirationVideoDto> getById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/videos/$id');
    final data = response.data;
    if (data == null) throw Exception('Invalid response');
    return InspirationVideoDto.fromJson(data);
  }

  Future<List<InspirationVideoDto>> getFeatured({int limit = 10}) async {
    final response = await _dio.get<dynamic>(
      '/videos/featured',
      queryParameters: {'limit': limit},
    );
    final data = response.data;
    if (data is! List) return [];
    return (data)
        .map((e) => InspirationVideoDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
