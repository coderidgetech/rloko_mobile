import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/calculate_tax_params.dart';
import '../../domain/repositories/tax_repository.dart';
import '../datasources/tax_remote_datasource.dart';

class TaxRepositoryImpl implements TaxRepository {
  TaxRepositoryImpl(this._dataSource);

  final TaxRemoteDataSource _dataSource;

  @override
  Future<double> calculate(CalculateTaxParams params) async {
    try {
      return await _dataSource.calculate(params);
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }
}
