import 'package:dio/dio.dart';

import '../../domain/entities/region_resolution.dart';
import '../../domain/repositories/region_resolve_repository.dart';
import '../datasources/region_resolve_remote_datasource.dart';

class RegionResolveRepositoryImpl implements RegionResolveRepository {
  RegionResolveRepositoryImpl(this._dataSource);

  final RegionResolveRemoteDataSource _dataSource;

  @override
  Future<RegionResolution> resolve({
    String? pincode,
    String? country,
    String? city,
  }) async {
    try {
      final dto = await _dataSource.resolve(
        pincode: pincode,
        country: country,
        city: city,
      );
      return dto.toEntity();
    } on DioException catch (e) {
      // The backend returns 400 when the input maps to no market — a
      // definitive "unresolved", not a transport failure. Surface it as such.
      final status = e.response?.statusCode;
      if (status == 400 || status == 422) {
        return RegionResolution.unresolved;
      }
      // 5xx / network / timeout → let the caller treat it as best-effort failure.
      rethrow;
    }
  }
}
