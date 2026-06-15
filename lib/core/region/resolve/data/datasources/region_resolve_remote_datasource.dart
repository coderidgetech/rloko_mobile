import 'package:dio/dio.dart';

import '../../../../network/dio_client.dart';
import '../dto/region_resolution_dto.dart';

/// Calls `GET /region/resolve` to resolve a market from a pincode/ZIP.
/// Returns a DTO; throws [DioException] on transport/HTTP errors (including the
/// 400 the backend returns for an unresolvable input).
class RegionResolveRemoteDataSource {
  RegionResolveRemoteDataSource(this._client);

  final DioClient _client;
  Dio get _dio => _client.dio;

  Future<RegionResolutionDto> resolve({
    String? pincode,
    String? country,
    String? city,
  }) async {
    final query = <String, dynamic>{
      if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
      if (country != null && country.isNotEmpty) 'country': country,
      if (city != null && city.isNotEmpty) 'city': city,
    };
    final response = await _dio.get<Map<String, dynamic>>(
      '/region/resolve',
      queryParameters: query,
    );
    return RegionResolutionDto.fromJson(response.data ?? const {});
  }
}
