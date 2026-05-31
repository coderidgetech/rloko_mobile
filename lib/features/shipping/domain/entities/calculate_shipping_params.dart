/// Request for POST /api/shipping/calculate (Shippo-backed when configured).
class CalculateShippingParams {
  const CalculateShippingParams({
    required this.country,
    this.state,
    this.city,
    this.address,
    this.postalCode,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    required this.subtotal,
    this.weight,
  });

  final String country;
  final String? state;
  final String? city;
  final String? address;
  final String? postalCode;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final double subtotal;
  final double? weight;
}
