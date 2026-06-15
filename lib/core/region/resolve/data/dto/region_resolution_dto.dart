import '../../../app_region.dart';
import '../../domain/entities/region_resolution.dart';

/// Maps the `GET /region/resolve` response
/// (`{market, currency, city, enabled, comingSoonMessage}`) to a domain entity.
class RegionResolutionDto {
  RegionResolutionDto({
    required this.market,
    required this.currency,
    required this.city,
    required this.enabled,
    required this.comingSoonMessage,
  });

  factory RegionResolutionDto.fromJson(Map<String, dynamic> json) {
    return RegionResolutionDto(
      market: (json['market'] as String?)?.toUpperCase() ?? '',
      currency: (json['currency'] as String?)?.toUpperCase() ?? '',
      city: json['city'] as String? ?? '',
      enabled: json['enabled'] == true,
      comingSoonMessage: json['comingSoonMessage'] as String? ?? '',
    );
  }

  final String market;
  final String currency;
  final String city;
  final bool enabled;
  final String comingSoonMessage;

  static AppRegion? _regionFromMarket(String market) {
    switch (market) {
      case 'IN':
        return AppRegion.india;
      case 'US':
        return AppRegion.unitedStates;
      default:
        return null;
    }
  }

  RegionResolution toEntity() {
    final region = _regionFromMarket(market);
    if (region == null) return RegionResolution.unresolved;
    return RegionResolution(
      region: region,
      currencyCode: currency.isNotEmpty ? currency : region.currencyCode,
      city: city,
      enabled: enabled,
      comingSoonMessage: comingSoonMessage,
    );
  }
}
