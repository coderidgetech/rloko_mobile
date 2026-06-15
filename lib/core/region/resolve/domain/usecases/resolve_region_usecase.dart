import '../entities/region_resolution.dart';
import '../repositories/region_resolve_repository.dart';

/// Resolves the market for a pincode/ZIP (with optional country/city hints).
class ResolveRegionUseCase {
  ResolveRegionUseCase(this._repository);

  final RegionResolveRepository _repository;

  Future<RegionResolution> call({
    String? pincode,
    String? country,
    String? city,
  }) {
    return _repository.resolve(pincode: pincode, country: country, city: city);
  }
}
