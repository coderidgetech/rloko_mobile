import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_region.dart';

/// Exposes region and price formatting to the widget tree (matches web CurrencyContext).
class CurrencyScope extends InheritedWidget {
  const CurrencyScope({
    super.key,
    required this.region,
    required super.child,
  });

  final AppRegion region;

  static CurrencyScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CurrencyScope>();
    assert(scope != null, 'No CurrencyScope found. Wrap app with CurrencyScope.');
    return scope!;
  }

  static CurrencyScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CurrencyScope>();
  }

  /// Format price: uses [inrPrice] when region is India, else [usdPrice]. Matches web formatPrice.
  String formatPrice(double usdPrice, [double? inrPrice]) {
    if (region == AppRegion.india) {
      final amount = inrPrice ?? (usdPrice * 75);
      return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount.round());
    }
    return '\$${usdPrice.toStringAsFixed(2)}';
  }

  /// Format an amount already in current currency (e.g. order total). Matches web formatAmount.
  String formatAmount(double amount) {
    if (region == AppRegion.india) {
      return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount.round());
    }
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  bool updateShouldNotify(CurrencyScope oldWidget) => oldWidget.region != region;
}
