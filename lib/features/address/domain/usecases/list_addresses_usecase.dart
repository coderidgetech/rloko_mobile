import '../entities/address_entity.dart';
import '../repositories/address_repository.dart';

class ListAddressesUseCase {
  ListAddressesUseCase(this._repo);
  final AddressRepository _repo;
  Future<List<AddressEntity>> call() => _repo.list();
}
