import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/promotion_entity.dart';
import '../../domain/repositories/promotion_repository.dart';
import '../datasources/promotion_remote_datasource.dart';
import '../dto/promotion_dto.dart';

class PromotionRepositoryImpl implements PromotionRepository {
  PromotionRepositoryImpl(this._dataSource);

  final PromotionRemoteDataSource _dataSource;

  @override
  Future<List<PromotionEntity>> list({bool activeOnly = true}) async {
    try {
      final list = await _dataSource.list(activeOnly: activeOnly);
      return list.map((e) => e.toEntity()).toList();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<ValidatePromotionResult> validate(String code, double subtotal) async {
    try {
      final data = await _dataSource.validate(code, subtotal);
      final valid = data['valid'] == true;
      PromotionEntity? promotion;
      if (data['promotion'] != null) {
        promotion = PromotionDto.fromJson(
          data['promotion'] as Map<String, dynamic>,
        ).toEntity();
      }
      final discount = (data['discount'] as num?)?.toDouble();
      return ValidatePromotionResult(
        valid: valid,
        promotion: promotion,
        discount: discount,
      );
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }
}
