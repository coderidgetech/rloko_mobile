import '../../../app_region.dart';

/// Outcome of resolving a market from a pincode/ZIP (or country hint).
///
/// Pure domain object — no JSON, no framework imports. [region] is `null` when
/// the input could not be mapped to a supported market.
class RegionResolution {
  const RegionResolution({
    required this.region,
    required this.currencyCode,
    required this.city,
    required this.enabled,
    required this.comingSoonMessage,
  });

  /// The resolved market, or `null` if unresolved.
  final AppRegion? region;

  /// ISO currency code for the market (e.g. `INR`, `USD`).
  final String currencyCode;

  /// Optional city hint echoed back; empty when unknown.
  final String city;

  /// Whether the market is currently open for shopping.
  final bool enabled;

  /// Message to show when [enabled] is `false` (e.g. "Launching soon").
  final String comingSoonMessage;

  bool get isResolved => region != null;

  /// Unresolved fallback for invalid input.
  static const RegionResolution unresolved = RegionResolution(
    region: null,
    currencyCode: '',
    city: '',
    enabled: false,
    comingSoonMessage: '',
  );
}
