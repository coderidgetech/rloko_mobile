import '../entities/site_config.dart';
import '../repositories/config_repository.dart';

class GetSiteConfigUseCase {
  GetSiteConfigUseCase(this._repo);
  final ConfigRepository _repo;

  Future<SiteConfig> call() => _repo.getConfig();
}
