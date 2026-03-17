import 'app_region.dart';

abstract class RegionRepository {
  /// Synchronous read for initial app state (SharedPreferences is sync).
  AppRegion getRegionSync();
  Future<AppRegion> getRegion();
  Future<void> setRegion(AppRegion region);
}
