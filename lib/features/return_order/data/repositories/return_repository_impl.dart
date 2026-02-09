import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/return_entity.dart';
import '../../domain/repositories/return_repository.dart';
import '../datasources/return_remote_datasource.dart';

class ReturnRepositoryImpl implements ReturnRepository {
  ReturnRepositoryImpl(this._dataSource);

  final ReturnRemoteDataSource _dataSource;

  @override
  Future<ReturnListResult> list({int limit = 20, int skip = 0}) async {
    try {
      final res = await _dataSource.list(limit: limit, skip: skip);
      return ReturnListResult(
        returns: res.returns.map((e) => e.toEntity()).toList(),
        total: res.total,
      );
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<ReturnEntity> getById(String id) async {
    try {
      final dto = await _dataSource.getById(id);
      return dto.toEntity();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }
}
