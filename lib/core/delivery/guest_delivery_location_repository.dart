/// Persists "deliver to" for signed-out users (Myntra-style pincode / ZIP before login).
abstract class GuestDeliveryLocationRepository {
  String? getIndiaPincode();
  String? getIndiaCityHint();
  String? getUsZip();
  Future<void> setIndiaPincode(String sixDigits, {String? cityHint});
  Future<void> setUsZip(String zip);
  Future<void> clearIndia();
  Future<void> clearUs();
}
