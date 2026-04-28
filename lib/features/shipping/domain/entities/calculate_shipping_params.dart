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

  Map<String, dynamic> toJson() => {
        'country': country,
        if (state != null && state!.isNotEmpty) 'state': state,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (address != null && address!.isNotEmpty) 'address': address,
        if (postalCode != null && postalCode!.isNotEmpty) 'postal_code': postalCode,
        if (firstName != null && firstName!.isNotEmpty) 'first_name': firstName,
        if (lastName != null && lastName!.isNotEmpty) 'last_name': lastName,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        'subtotal': subtotal,
        if (weight != null && weight! > 0) 'weight': weight,
      };
}
