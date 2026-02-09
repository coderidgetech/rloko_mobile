import '../repositories/config_repository.dart';

class GetSiteConfigUseCase {
  GetSiteConfigUseCase(this._repo);
  final ConfigRepository _repo;

  Future<Map<String, dynamic>> call() => _repo.getConfig();
}
