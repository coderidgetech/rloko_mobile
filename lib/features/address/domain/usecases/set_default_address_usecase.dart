import '../repositories/address_repository.dart';

class SetDefaultAddressUseCase {
  SetDefaultAddressUseCase(this._repo);
  final AddressRepository _repo;
  Future<void> call(String id) => _repo.setDefault(id);
}
