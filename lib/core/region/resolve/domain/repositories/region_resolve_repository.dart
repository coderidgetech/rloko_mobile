import '../entities/region_resolution.dart';

/// Resolves a market (and its availability) from a pincode/ZIP or country hint.
/// Implementations throw on transport failure; callers handle the error.
abstract class RegionResolveRepository {
  Future<RegionResolution> resolve({
    String? pincode,
    String? country,
    String? city,
  });
}
