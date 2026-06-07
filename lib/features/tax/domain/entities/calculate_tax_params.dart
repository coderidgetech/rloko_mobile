/// Request for POST /api/tax/calculate. Subtotal is in USD (backend returns
/// the tax amount in the same currency), matching the web checkout.
class CalculateTaxParams {
  const CalculateTaxParams({
    required this.country,
    this.state,
    this.city,
    this.postalCode,
    required this.subtotal,
  });

  final String country;
  final String? state;
  final String? city;
  final String? postalCode;
  final double subtotal;
}
