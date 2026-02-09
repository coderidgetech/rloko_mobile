import '../../domain/repositories/config_repository.dart';
import '../datasources/config_remote_datasource.dart';

class ConfigRepositoryImpl implements ConfigRepository {
  ConfigRepositoryImpl(this._dataSource);
  final ConfigRemoteDataSource _dataSource;

  @override
  Future<Map<String, dynamic>> getConfig() => _dataSource.getConfig();
}
