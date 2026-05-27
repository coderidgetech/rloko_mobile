import 'package:shared_preferences/shared_preferences.dart';

import 'guest_delivery_location_repository.dart';

const _kInPin = 'guest_delivery_in_pincode';
const _kInCity = 'guest_delivery_in_city';
const _kUsZip = 'guest_delivery_us_zip';

class GuestDeliveryLocationRepositoryImpl implements GuestDeliveryLocationRepository {
  GuestDeliveryLocationRepositoryImpl(this._prefs);
  final SharedPreferences _prefs;

  @override
  String? getIndiaPincode() {
    final v = _prefs.getString(_kInPin);
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  @override
  String? getIndiaCityHint() {
    final v = _prefs.getString(_kInCity);
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  @override
  String? getUsZip() {
    final v = _prefs.getString(_kUsZip);
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  @override
  Future<void> setIndiaPincode(String sixDigits, {String? cityHint}) async {
    await _prefs.setString(_kInPin, sixDigits.trim());
    if (cityHint != null && cityHint.trim().isNotEmpty) {
      await _prefs.setString(_kInCity, cityHint.trim());
    } else {
      await _prefs.remove(_kInCity);
    }
  }

  @override
  Future<void> setUsZip(String zip) async {
    await _prefs.setString(_kUsZip, zip.trim());
  }

  @override
  Future<void> clearIndia() async {
    await _prefs.remove(_kInPin);
    await _prefs.remove(_kInCity);
  }

  @override
  Future<void> clearUs() async {
    await _prefs.remove(_kUsZip);
  }
}
