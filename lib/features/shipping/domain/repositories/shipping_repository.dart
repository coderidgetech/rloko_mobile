import '../entities/shipping_method_entity.dart';

abstract class ShippingRepository {
  Future<List<ShippingMethodEntity>> listMethods({bool activeOnly = true});
}
