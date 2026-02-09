import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/shipping_method_entity.dart';
import '../../domain/repositories/shipping_repository.dart';
import '../datasources/shipping_remote_datasource.dart';

class ShippingRepositoryImpl implements ShippingRepository {
  ShippingRepositoryImpl(this._dataSource);

  final ShippingRemoteDataSource _dataSource;

  @override
  Future<List<ShippingMethodEntity>> listMethods({bool activeOnly = true}) async {
    try {
      final list = await _dataSource.listMethods(activeOnly: activeOnly);
      return list.map((e) => e.toEntity()).toList();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }
}
