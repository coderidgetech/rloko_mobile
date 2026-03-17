/// App region for currency/display; matches web CurrencyContext (India | United States).
enum AppRegion {
  india,
  unitedStates,
}

extension AppRegionX on AppRegion {
  String get displayName {
    switch (this) {
      case AppRegion.india:
        return 'India';
      case AppRegion.unitedStates:
        return 'United States';
    }
  }

  String get currencyCode => this == AppRegion.india ? 'INR' : 'USD';
  String get currencySymbol => this == AppRegion.india ? '₹' : '\$';
}
