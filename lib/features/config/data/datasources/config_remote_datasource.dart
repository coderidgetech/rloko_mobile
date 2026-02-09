import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

/// Fetches site configuration from the backend (GET /api/config).
class ConfigRemoteDataSource {
  ConfigRemoteDataSource(this._client);

  final DioClient _client;
  Dio get _dio => _client.dio;

  Future<Map<String, dynamic>> getConfig() async {
    final response = await _dio.get<Map<String, dynamic>>('/config');
    return response.data ?? {};
  }
}
