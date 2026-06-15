import 'app_region.dart';

abstract class RegionRepository {
  /// Synchronous read for initial app state (SharedPreferences is sync).
  AppRegion getRegionSync();
  Future<AppRegion> getRegion();
  Future<void> setRegion(AppRegion region);

  /// Whether the user has explicitly chosen a delivery location yet. Used to
  /// enforce the first-launch location gate. Synchronous for routing redirects.
  bool hasChosenLocation();

  /// Marks that a location has been chosen, so the gate is no longer enforced.
  Future<void> markLocationChosen();
}
