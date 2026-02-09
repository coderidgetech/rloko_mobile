import '../entities/address_entity.dart';
import '../repositories/address_repository.dart';

class ListAddressesUseCase {
  ListAddressesUseCase(this._repo);
  final AddressRepository _repo;
  Future<List<AddressEntity>> call() => _repo.list();
}

class GetAddressByIdUseCase {
  GetAddressByIdUseCase(this._repo);
  final AddressRepository _repo;
  Future<AddressEntity> call(String id) => _repo.getById(id);
}

class CreateAddressUseCase {
  CreateAddressUseCase(this._repo);
  final AddressRepository _repo;
  Future<AddressEntity> call(AddressEntity address) => _repo.create(address);
}

class UpdateAddressUseCase {
  UpdateAddressUseCase(this._repo);
  final AddressRepository _repo;
  Future<AddressEntity> call(String id, AddressEntity address) =>
      _repo.update(id, address);
}

class DeleteAddressUseCase {
  DeleteAddressUseCase(this._repo);
  final AddressRepository _repo;
  Future<void> call(String id) => _repo.delete(id);
}

class SetDefaultAddressUseCase {
  SetDefaultAddressUseCase(this._repo);
  final AddressRepository _repo;
  Future<void> call(String id) => _repo.setDefault(id);
}
