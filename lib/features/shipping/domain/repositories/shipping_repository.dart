import '../entities/calculate_shipping_params.dart';
import '../entities/shipping_method_entity.dart';

abstract class ShippingRepository {
  Future<List<ShippingMethodEntity>> listMethods({bool activeOnly = true});

  Future<List<ShippingMethodEntity>> calculate(CalculateShippingParams params);
}
