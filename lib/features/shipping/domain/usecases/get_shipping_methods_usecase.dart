import '../entities/shipping_method_entity.dart';
import '../repositories/shipping_repository.dart';

class GetShippingMethodsUseCase {
  GetShippingMethodsUseCase(this._repository);
  final ShippingRepository _repository;

  Future<List<ShippingMethodEntity>> call({bool activeOnly = true}) =>
      _repository.listMethods(activeOnly: activeOnly);
}
