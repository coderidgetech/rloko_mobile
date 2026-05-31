import '../entities/address_entity.dart';
import '../repositories/address_repository.dart';

class CreateAddressUseCase {
  CreateAddressUseCase(this._repo);
  final AddressRepository _repo;
  Future<AddressEntity> call(AddressEntity address) => _repo.create(address);
}
