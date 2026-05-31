import '../repositories/address_repository.dart';

class DeleteAddressUseCase {
  DeleteAddressUseCase(this._repo);
  final AddressRepository _repo;
  Future<void> call(String id) => _repo.delete(id);
}
