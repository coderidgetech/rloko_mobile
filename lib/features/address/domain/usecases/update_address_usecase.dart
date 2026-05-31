import '../entities/address_entity.dart';
import '../repositories/address_repository.dart';

class UpdateAddressUseCase {
  UpdateAddressUseCase(this._repo);
  final AddressRepository _repo;
  Future<AddressEntity> call(String id, AddressEntity address) =>
      _repo.update(id, address);
}
