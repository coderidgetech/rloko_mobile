import '../entities/calculate_shipping_params.dart';
import '../entities/shipping_method_entity.dart';
import '../repositories/shipping_repository.dart';

class CalculateShippingUseCase {
  CalculateShippingUseCase(this._repository);

  final ShippingRepository _repository;

  Future<List<ShippingMethodEntity>> call(CalculateShippingParams params) =>
      _repository.calculate(params);
}
