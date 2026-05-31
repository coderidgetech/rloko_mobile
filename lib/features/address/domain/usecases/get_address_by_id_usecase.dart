import '../entities/address_entity.dart';
import '../repositories/address_repository.dart';

class GetAddressByIdUseCase {
  GetAddressByIdUseCase(this._repo);
  final AddressRepository _repo;
  Future<AddressEntity> call(String id) => _repo.getById(id);
}
