/// Standard form hint messages for consistency across the app.
/// Use these instead of example values like "John Doe" or "you@example.com".
class FormHints {
  FormHints._();

  // Auth
  static const String email = 'Enter your email address';
  static const String password = 'Enter your password';
  static const String fullName = 'Enter your full name';
  static const String confirmPassword = 'Confirm your password';

  // Address
  static const String phone = 'Enter your phone number';
  static const String streetAddress = 'Enter street address';
  static const String city = 'Enter city';
  static const String state = 'Enter state or province';
  static const String zipCode = 'Enter ZIP or postal code';
  static const String country = 'Enter country';

  // Promo / search
  static const String promoCode = 'Enter promo code';
  static const String searchProducts = 'Search products...';
  static const String searchArea = 'Enter area or street name';

  // Payment
  static const String cardNumber = 'Enter card number';
  static const String nameOnCard = 'Enter name on card';
  static const String expiryDate = 'MM/YY';
  static const String cvv = 'CVV';
  static const String upiId = 'Enter UPI ID';
}
