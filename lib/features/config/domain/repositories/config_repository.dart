import '../entities/site_config.dart';

abstract class ConfigRepository {
  Future<SiteConfig> getConfig();
}
