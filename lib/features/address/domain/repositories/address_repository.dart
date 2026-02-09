import '../entities/address_entity.dart';

abstract class AddressRepository {
  Future<List<AddressEntity>> list();

  Future<AddressEntity> getById(String id);

  Future<AddressEntity> create(AddressEntity address);

  Future<AddressEntity> update(String id, AddressEntity address);

  Future<void> delete(String id);

  Future<void> setDefault(String id);
}
