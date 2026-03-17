import 'package:shared_preferences/shared_preferences.dart';

import 'app_region.dart';
import 'region_repository.dart';

const String _keySelectedCountry = 'selectedCountry';

class RegionRepositoryImpl implements RegionRepository {
  RegionRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  static AppRegion _fromString(String? v) {
    if (v == null) return AppRegion.unitedStates;
    switch (v) {
      case 'India':
        return AppRegion.india;
      case 'United States':
        return AppRegion.unitedStates;
      default:
        return AppRegion.unitedStates;
    }
  }

  @override
  AppRegion getRegionSync() => _fromString(_prefs.getString(_keySelectedCountry));

  @override
  Future<AppRegion> getRegion() async => getRegionSync();

  @override
  Future<void> setRegion(AppRegion region) async {
    await _prefs.setString(_keySelectedCountry, region.displayName);
  }
}
