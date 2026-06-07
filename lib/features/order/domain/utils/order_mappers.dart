import '../../../../core/constants/currency_constants.dart';
import '../../../../core/region/app_region.dart';
import '../../../address/domain/entities/address_entity.dart';
import '../../../cart/domain/entities/cart_item_entity.dart';
import '../entities/order_entity.dart';

/// Gift wrap charge per gift unit, in INR — matches web `GIFT_PACKING_PER_ITEM`.
const double kGiftPackingPerItemInr = 50.0;

/// INR→USD rate for converting the ₹50 gift charge on non-INR orders. Matches
/// web's `USD_TO_INR` (and the backend's default `INRPerUSD`) so both clients
/// send an identical `gift_packing_charge`. Deliberately distinct from
/// [kUsdToInrDisplay] (the app's display rate, used only to render INR totals).
const double kGiftInrPerUsd = 75.0;

/// Number of gift *units* (sum of quantities of gift-marked lines). Web charges
/// per unit (`item.quantity * 50`), so we mirror that rather than counting lines.
int giftUnitCount(
  Iterable<CartItemEntity> items,
  Set<String> giftItemKeys,
) {
  if (giftItemKeys.isEmpty) return 0;
  return items
      .where((i) => giftItemKeys.contains('${i.productId}-${i.size}'))
      .fold(0, (s, i) => s + i.quantity);
}

/// Per-unit gift charge in USD for non-INR orders (matches web's ₹50 ÷ 75).
double giftPerItemUsd() => kGiftPackingPerItemInr / kGiftInrPerUsd;

/// Gift packing charge in the order's own currency — the value sent to the
/// backend, which adds it to the (region-priced) order total verbatim. India
/// orders are priced in INR, so send ₹50/unit; elsewhere send the USD
/// equivalent. Mirrors web's `giftPackingDisplay` on `gift_packing_charge`.
double giftChargeForOrder(int units, AppRegion region) =>
    region == AppRegion.india
        ? units * kGiftPackingPerItemInr
        : units * giftPerItemUsd();

/// Gift charge expressed in USD for the checkout summary's USD-based math, so
/// the per-region display matches the amount sent. For India the summary
/// multiplies USD by [kUsdToInrDisplay], so we divide by that to land back on
/// ₹50; elsewhere it is the same USD value that gets sent.
double giftChargeSummaryUsd(int units, AppRegion region) =>
    region == AppRegion.india
        ? units * (kGiftPackingPerItemInr / kUsdToInrDisplay)
        : units * giftPerItemUsd();

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
