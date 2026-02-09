import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/inspiration_video_entity.dart';
import '../../domain/repositories/video_repository.dart';
import '../datasources/video_remote_datasource.dart';

class VideoRepositoryImpl implements VideoRepository {
  VideoRepositoryImpl(this._dataSource);

  final VideoRemoteDataSource _dataSource;

  @override
  Future<List<InspirationVideoEntity>> list({
    int? limit,
    int? skip,
    String? category,
    bool? featured,
  }) async {
    try {
      final list = await _dataSource.list(
        limit: limit,
        skip: skip,
        category: category,
        featured: featured,
      );
      return list.map((e) => e.toEntity()).toList();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<InspirationVideoEntity> getById(String id) async {
    try {
      final dto = await _dataSource.getById(id);
      return dto.toEntity();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<List<InspirationVideoEntity>> getFeatured({int limit = 10}) async {
    try {
      final list = await _dataSource.getFeatured(limit: limit);
      return list.map((e) => e.toEntity()).toList();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }
}
