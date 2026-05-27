import '../region/app_region.dart';

/// Delivery and shipping policy copy. Can be overridden by site config API when available.
class DeliveryConstants {
  DeliveryConstants._();

  /// Free delivery threshold (e.g. "Free delivery on orders over \$50")
  static const String freeDeliveryThreshold = r'Free delivery on orders over $50';

  /// Free-shipping line aligned with [CurrencyScope] / storefront (India vs US).
  static String freeShippingPromoLine(AppRegion region) {
    if (region == AppRegion.india) {
      return 'Free shipping on orders over ₹2,000';
    }
    return r'Free shipping on orders over $50';
  }

  /// Standard delivery timeframe
  static const String standardDeliveryDays = 'Standard delivery: 3-5 business days';

  /// Estimated delivery text for address cards
  static const String estimatedDelivery = '3-5 business days';

  /// Express delivery note
  static const String expressDeliveryNote = 'Express delivery available at checkout';

  /// Shipping cost placeholder when not yet calculated
  static const String calculatedAtCheckout = 'Calculated at checkout';

  /// Delivery info bullet list for checkout/address pages
  static String deliveryInfoBulletsFor(AppRegion region) =>
      '• ${freeShippingPromoLine(region)}\n'
      '• $standardDeliveryDays\n'
      '• $expressDeliveryNote';

  /// Returns/refunds
  static const String returnInspectionDays = 'Inspection within 3-5 business days';
  static const String returnProcessingNote = '3-5 business days after we receive your return';
}
