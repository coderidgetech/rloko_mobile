import '../../../address/domain/entities/address_entity.dart';
import '../../../cart/domain/entities/cart_item_entity.dart';
import '../entities/order_entity.dart';

/// Maps an [AddressEntity] and [userEmail] to a [ShippingInfoEntity].
ShippingInfoEntity addressToShipping(AddressEntity a, String userEmail) {
  final parts = a.name.trim().split(RegExp(r'\s+'));
  final firstName = parts.isNotEmpty ? parts.first : a.name;
  final lastName = parts.length > 1 ? parts.skip(1).join(' ') : '';
  final addressLine =
      a.addressLine +
      (a.addressLine2 != null && a.addressLine2!.isNotEmpty
          ? ', ${a.addressLine2}'
          : '');
  return ShippingInfoEntity(
    firstName: firstName,
    lastName: lastName,
    email: userEmail,
    phone: a.mobile,
    address: addressLine,
    city: a.city,
    state: a.state,
    zipCode: a.pincode,
    country: a.country,
  );
}

/// Converts a list of [CartItemEntity] to [OrderItemEntity] items.
///
/// [giftItemKeys] is a set of `'productId-size'` strings marking gift items.
List<OrderItemEntity> cartItemsToOrderItems(
  List<CartItemEntity> items, {
  Set<String> giftItemKeys = const {},
}) {
  return items.map((item) {
    final key = '${item.productId}-${item.size}';
    final isGift = giftItemKeys.contains(key);
    return OrderItemEntity(
      productId: item.productId,
      productName: item.productName,
      image: item.image,
      price: item.price,
      size: item.size,
      quantity: item.quantity,
      isGift: isGift,
      giftWrapColor: isGift ? (item.giftWrapColor ?? 'default') : null,
      giftMessage: isGift ? item.giftMessage : null,
    );
  }).toList();
}

/// Returns the Stripe currency code for the given [country] string.
String stripeCurrencyForCountry(String country) {
  final c = country.trim().toLowerCase();
  if (c == 'in' || c == 'india' || c.contains('india')) {
    return 'inr';
  }
  return 'usd';
}

/// Returns the two-letter ISO country code expected by Stripe's Address.country
/// for the given [country] string.
String stripeCountryCodeForShipping(String country) {
  final c = country.trim().toLowerCase();
  if (c == 'in' || c == 'india' || c.contains('india')) return 'IN';
  if (c == 'us' || c == 'usa' || c.contains('united states')) return 'US';
  if (country.trim().length == 2) return country.trim().toUpperCase();
  return 'IN';
}
