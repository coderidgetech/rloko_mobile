import '../../domain/entities/site_config.dart';
import '../../domain/repositories/config_repository.dart';
import '../datasources/config_remote_datasource.dart';

class ConfigRepositoryImpl implements ConfigRepository {
  ConfigRepositoryImpl(this._dataSource);
  final ConfigRemoteDataSource _dataSource;

  @override
  Future<SiteConfig> getConfig() async {
    final raw = await _dataSource.getConfig();
    // Support both { design, general, ... } and { data: { design, general, ... } }
    final map = raw['data'] is Map
        ? Map<String, dynamic>.from(raw['data'] as Map)
        : raw;
    return SiteConfig.fromMap(map);
  }
}
