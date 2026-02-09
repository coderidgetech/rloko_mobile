/// Country model for phone input; matches React MobileLoginPage COUNTRIES.
class Country {
  const Country({
    required this.code,
    required this.name,
    required this.dialCode,
    required this.flag,
  });

  final String code;
  final String name;
  final String dialCode;
  final String flag;

  static const List<Country> all = [
    Country(code: 'US', name: 'United States', dialCode: '+1', flag: '🇺🇸'),
    Country(code: 'IN', name: 'India', dialCode: '+91', flag: '🇮🇳'),
    Country(code: 'GB', name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧'),
    Country(code: 'CA', name: 'Canada', dialCode: '+1', flag: '🇨🇦'),
    Country(code: 'AU', name: 'Australia', dialCode: '+61', flag: '🇦🇺'),
    Country(code: 'DE', name: 'Germany', dialCode: '+49', flag: '🇩🇪'),
    Country(code: 'FR', name: 'France', dialCode: '+33', flag: '🇫🇷'),
    Country(code: 'IT', name: 'Italy', dialCode: '+39', flag: '🇮🇹'),
    Country(code: 'ES', name: 'Spain', dialCode: '+34', flag: '🇪🇸'),
    Country(code: 'MX', name: 'Mexico', dialCode: '+52', flag: '🇲🇽'),
    Country(code: 'BR', name: 'Brazil', dialCode: '+55', flag: '🇧🇷'),
    Country(code: 'JP', name: 'Japan', dialCode: '+81', flag: '🇯🇵'),
    Country(code: 'CN', name: 'China', dialCode: '+86', flag: '🇨🇳'),
    Country(code: 'KR', name: 'South Korea', dialCode: '+82', flag: '🇰🇷'),
    Country(code: 'SG', name: 'Singapore', dialCode: '+65', flag: '🇸🇬'),
    Country(code: 'AE', name: 'UAE', dialCode: '+971', flag: '🇦🇪'),
    Country(code: 'SA', name: 'Saudi Arabia', dialCode: '+966', flag: '🇸🇦'),
    Country(code: 'ZA', name: 'South Africa', dialCode: '+27', flag: '🇿🇦'),
    Country(code: 'NL', name: 'Netherlands', dialCode: '+31', flag: '🇳🇱'),
    Country(code: 'SE', name: 'Sweden', dialCode: '+46', flag: '🇸🇪'),
    Country(code: 'CH', name: 'Switzerland', dialCode: '+41', flag: '🇨🇭'),
    Country(code: 'BE', name: 'Belgium', dialCode: '+32', flag: '🇧🇪'),
    Country(code: 'AT', name: 'Austria', dialCode: '+43', flag: '🇦🇹'),
    Country(code: 'NO', name: 'Norway', dialCode: '+47', flag: '🇳🇴'),
    Country(code: 'DK', name: 'Denmark', dialCode: '+45', flag: '🇩🇰'),
    Country(code: 'FI', name: 'Finland', dialCode: '+358', flag: '🇫🇮'),
    Country(code: 'PL', name: 'Poland', dialCode: '+48', flag: '🇵🇱'),
    Country(code: 'RU', name: 'Russia', dialCode: '+7', flag: '🇷🇺'),
    Country(code: 'TR', name: 'Turkey', dialCode: '+90', flag: '🇹🇷'),
    Country(code: 'ID', name: 'Indonesia', dialCode: '+62', flag: '🇮🇩'),
    Country(code: 'MY', name: 'Malaysia', dialCode: '+60', flag: '🇲🇾'),
    Country(code: 'TH', name: 'Thailand', dialCode: '+66', flag: '🇹🇭'),
    Country(code: 'VN', name: 'Vietnam', dialCode: '+84', flag: '🇻🇳'),
    Country(code: 'PH', name: 'Philippines', dialCode: '+63', flag: '🇵🇭'),
    Country(code: 'NZ', name: 'New Zealand', dialCode: '+64', flag: '🇳🇿'),
    Country(code: 'AR', name: 'Argentina', dialCode: '+54', flag: '🇦🇷'),
    Country(code: 'CL', name: 'Chile', dialCode: '+56', flag: '🇨🇱'),
    Country(code: 'CO', name: 'Colombia', dialCode: '+57', flag: '🇨🇴'),
    Country(code: 'PE', name: 'Peru', dialCode: '+51', flag: '🇵🇪'),
    Country(code: 'EG', name: 'Egypt', dialCode: '+20', flag: '🇪🇬'),
    Country(code: 'NG', name: 'Nigeria', dialCode: '+234', flag: '🇳🇬'),
    Country(code: 'KE', name: 'Kenya', dialCode: '+254', flag: '🇰🇪'),
    Country(code: 'GH', name: 'Ghana', dialCode: '+233', flag: '🇬🇭'),
    Country(code: 'IL', name: 'Israel', dialCode: '+972', flag: '🇮🇱'),
    Country(code: 'PK', name: 'Pakistan', dialCode: '+92', flag: '🇵🇰'),
    Country(code: 'BD', name: 'Bangladesh', dialCode: '+880', flag: '🇧🇩'),
    Country(code: 'LK', name: 'Sri Lanka', dialCode: '+94', flag: '🇱🇰'),
    Country(code: 'PT', name: 'Portugal', dialCode: '+351', flag: '🇵🇹'),
    Country(code: 'GR', name: 'Greece', dialCode: '+30', flag: '🇬🇷'),
    Country(code: 'IE', name: 'Ireland', dialCode: '+353', flag: '🇮🇪'),
  ];

  static Country get defaultCountry => all[1]; // India (+91)
}
