/// Shared helpers for saved delivery addresses (India + United States + legacy free text).
library;

/// Normalize stored/API country strings to a canonical display value used across the app.
String normalizeAddressCountry(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'United States';
  final l = raw.trim().toLowerCase();
  if (l == 'india' || l == 'in') return 'India';
  if (l == 'united states' || l == 'us' || l == 'usa' || l == 'u.s.' || l == 'u.s.a.') {
    return 'United States';
  }
  return raw.trim();
}

bool isIndiaCountry(String? raw) => normalizeAddressCountry(raw) == 'India';

bool isUnitedStatesCountry(String? raw) => normalizeAddressCountry(raw) == 'United States';

String? validateMobileForCountry(String? value, String country) {
  final v = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (v.isEmpty) return 'Phone number is required';
  if (isIndiaCountry(country) || isUnitedStatesCountry(country)) {
    if (v.length != 10) return 'Enter a valid 10-digit number';
    return null;
  }
  if (v.length < 8) return 'Enter a valid phone number';
  if (v.length > 15) return 'Phone number is too long';
  return null;
}

String? validatePincodeForCountry(String? value, String country) {
  final d = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (d.isEmpty) return 'Pincode or ZIP is required';
  if (isIndiaCountry(country)) {
    if (d.length != 6) return 'Enter a 6-digit PIN code';
    return null;
  }
  if (isUnitedStatesCountry(country)) {
    if (d.length != 5 && d.length != 9) {
      return 'Enter a 5-digit ZIP or 9 digits (ZIP+4)';
    }
    return null;
  }
  if (d.length < 3) return 'Enter a valid postal code';
  return null;
}

String? validateFullName(String? value) {
  final t = (value ?? '').trim();
  if (t.isEmpty) return 'Full name is required';
  if (t.length < 2) return 'Enter at least 2 characters';
  return null;
}
