import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../dto/category_dto.dart';

class CategoryRemoteDataSource {
  CategoryRemoteDataSource(this._client);

  final DioClient _client;
  Dio get _dio => _client.dio;

  Future<List<CategoryDto>> list() async {
    final response = await _dio.get<List<dynamic>>('/categories');
    final data = response.data;
    if (data == null) return [];
    return data
        .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CategoryDto> getById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/categories/$id');
    final data = response.data;
    if (data == null) throw Exception('Invalid response');
    return CategoryDto.fromJson(data);
  }
}
