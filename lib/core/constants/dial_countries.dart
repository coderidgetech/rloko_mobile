// Mirrors frontend/src/app/lib/dialCountries.ts — same order and codes for API parity.

class DialCountry {
  const DialCountry({
    required this.code,
    required this.name,
    required this.dialCode,
    required this.flag,
  });

  final String code;
  final String name;
  final String dialCode;
  final String flag;
}

/// Default second entry (India), matching web `useState(DIAL_COUNTRIES[1])`.
const List<DialCountry> kDialCountries = [
  DialCountry(code: 'US', name: 'United States', dialCode: '+1', flag: '🇺🇸'),
  DialCountry(code: 'IN', name: 'India', dialCode: '+91', flag: '🇮🇳'),
  DialCountry(code: 'GB', name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧'),
  DialCountry(code: 'CA', name: 'Canada', dialCode: '+1', flag: '🇨🇦'),
  DialCountry(code: 'AU', name: 'Australia', dialCode: '+61', flag: '🇦🇺'),
  DialCountry(code: 'DE', name: 'Germany', dialCode: '+49', flag: '🇩🇪'),
  DialCountry(code: 'FR', name: 'France', dialCode: '+33', flag: '🇫🇷'),
  DialCountry(code: 'IT', name: 'Italy', dialCode: '+39', flag: '🇮🇹'),
  DialCountry(code: 'ES', name: 'Spain', dialCode: '+34', flag: '🇪🇸'),
  DialCountry(code: 'MX', name: 'Mexico', dialCode: '+52', flag: '🇲🇽'),
  DialCountry(code: 'BR', name: 'Brazil', dialCode: '+55', flag: '🇧🇷'),
  DialCountry(code: 'JP', name: 'Japan', dialCode: '+81', flag: '🇯🇵'),
  DialCountry(code: 'CN', name: 'China', dialCode: '+86', flag: '🇨🇳'),
  DialCountry(code: 'KR', name: 'South Korea', dialCode: '+82', flag: '🇰🇷'),
  DialCountry(code: 'SG', name: 'Singapore', dialCode: '+65', flag: '🇸🇬'),
  DialCountry(code: 'AE', name: 'UAE', dialCode: '+971', flag: '🇦🇪'),
  DialCountry(code: 'SA', name: 'Saudi Arabia', dialCode: '+966', flag: '🇸🇦'),
  DialCountry(code: 'ZA', name: 'South Africa', dialCode: '+27', flag: '🇿🇦'),
  DialCountry(code: 'NL', name: 'Netherlands', dialCode: '+31', flag: '🇳🇱'),
  DialCountry(code: 'SE', name: 'Sweden', dialCode: '+46', flag: '🇸🇪'),
  DialCountry(code: 'CH', name: 'Switzerland', dialCode: '+41', flag: '🇨🇭'),
  DialCountry(code: 'BE', name: 'Belgium', dialCode: '+32', flag: '🇧🇪'),
  DialCountry(code: 'AT', name: 'Austria', dialCode: '+43', flag: '🇦🇹'),
  DialCountry(code: 'NO', name: 'Norway', dialCode: '+47', flag: '🇳🇴'),
  DialCountry(code: 'DK', name: 'Denmark', dialCode: '+45', flag: '🇩🇰'),
  DialCountry(code: 'FI', name: 'Finland', dialCode: '+358', flag: '🇫🇮'),
  DialCountry(code: 'PL', name: 'Poland', dialCode: '+48', flag: '🇵🇱'),
  DialCountry(code: 'RU', name: 'Russia', dialCode: '+7', flag: '🇷🇺'),
  DialCountry(code: 'TR', name: 'Turkey', dialCode: '+90', flag: '🇹🇷'),
  DialCountry(code: 'ID', name: 'Indonesia', dialCode: '+62', flag: '🇮🇩'),
  DialCountry(code: 'MY', name: 'Malaysia', dialCode: '+60', flag: '🇲🇾'),
  DialCountry(code: 'TH', name: 'Thailand', dialCode: '+66', flag: '🇹🇭'),
  DialCountry(code: 'VN', name: 'Vietnam', dialCode: '+84', flag: '🇻🇳'),
  DialCountry(code: 'PH', name: 'Philippines', dialCode: '+63', flag: '🇵🇭'),
  DialCountry(code: 'NZ', name: 'New Zealand', dialCode: '+64', flag: '🇳🇿'),
  DialCountry(code: 'AR', name: 'Argentina', dialCode: '+54', flag: '🇦🇷'),
  DialCountry(code: 'CL', name: 'Chile', dialCode: '+56', flag: '🇨🇱'),
  DialCountry(code: 'CO', name: 'Colombia', dialCode: '+57', flag: '🇨🇴'),
  DialCountry(code: 'PE', name: 'Peru', dialCode: '+51', flag: '🇵🇪'),
  DialCountry(code: 'EG', name: 'Egypt', dialCode: '+20', flag: '🇪🇬'),
  DialCountry(code: 'NG', name: 'Nigeria', dialCode: '+234', flag: '🇳🇬'),
  DialCountry(code: 'KE', name: 'Kenya', dialCode: '+254', flag: '🇰🇪'),
  DialCountry(code: 'GH', name: 'Ghana', dialCode: '+233', flag: '🇬🇭'),
  DialCountry(code: 'IL', name: 'Israel', dialCode: '+972', flag: '🇮🇱'),
  DialCountry(code: 'PK', name: 'Pakistan', dialCode: '+92', flag: '🇵🇰'),
  DialCountry(code: 'BD', name: 'Bangladesh', dialCode: '+880', flag: '🇧🇩'),
  DialCountry(code: 'LK', name: 'Sri Lanka', dialCode: '+94', flag: '🇱🇰'),
  DialCountry(code: 'PT', name: 'Portugal', dialCode: '+351', flag: '🇵🇹'),
  DialCountry(code: 'GR', name: 'Greece', dialCode: '+30', flag: '🇬🇷'),
  DialCountry(code: 'IE', name: 'Ireland', dialCode: '+353', flag: '🇮🇪'),
];

String buildPhoneDigitsForApi(String dialCode, String localInput) {
  final dialDigits = dialCode.replaceAll(RegExp(r'\D'), '');
  final localDigits = localInput.replaceAll(RegExp(r'\D'), '');
  return dialDigits + localDigits;
}

List<DialCountry> filterDialCountries(String search) {
  final q = search.toLowerCase().trim();
  if (q.isEmpty) return List<DialCountry>.from(kDialCountries);
  return kDialCountries.where((c) {
    return c.name.toLowerCase().contains(q) ||
        c.dialCode.contains(search.trim()) ||
        c.code.toLowerCase().contains(q);
  }).toList();
}
