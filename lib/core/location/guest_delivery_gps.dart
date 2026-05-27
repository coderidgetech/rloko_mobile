import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

sealed class GuestDeliveryGpsResult {
  const GuestDeliveryGpsResult();
}

class GuestDeliveryGpsSuccess extends GuestDeliveryGpsResult {
  const GuestDeliveryGpsSuccess({
    required this.isIndia,
    required this.postalCode,
    this.city,
  });

  final bool isIndia;
  final String postalCode;
  final String? city;
}

class GuestDeliveryGpsFailure extends GuestDeliveryGpsResult {
  const GuestDeliveryGpsFailure(this.message);
  final String message;
}

/// Resolves a delivery pin / ZIP from GPS + platform reverse geocoding (Myntra-style).
class GuestDeliveryGps {
  GuestDeliveryGps._();

  /// Rough bounds when [Placemark.isoCountryCode] is missing (emulators / buggy geocoders).
  static bool _latLngLooksLikeIndia(double lat, double lng) {
    return lat >= 5.0 && lat <= 38.0 && lng >= 64.0 && lng <= 99.0;
  }

  static bool _latLngLooksLikeContiguousUS(double lat, double lng) {
    return lat >= 23.0 && lat <= 51.0 && lng >= -128.0 && lng <= -65.0;
  }

  static bool _isValidPos(Position? p) =>
      p != null && p.latitude.isFinite && p.longitude.isFinite;

  /// [getLastKnownPosition] + multiple accuracies: fixes many simulator / indoor failures.
  static Future<Position> _obtainPosition() async {
    final cached = await Geolocator.getLastKnownPosition();

    Future<Position?> trySingleFix(LocationAccuracy accuracy, int timeLimitSec) async {
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: accuracy,
            timeLimit: Duration(seconds: timeLimitSec),
          ),
        );
      } on LocationServiceDisabledException {
        rethrow;
      } on PermissionDeniedException {
        rethrow;
      } on TimeoutException {
        return null;
      } on PositionUpdateException {
        return null;
      } catch (_) {
        return null;
      }
    }

    for (final t in <(LocationAccuracy, int)>[
      (LocationAccuracy.medium, 30),
      (LocationAccuracy.low, 30),
      (LocationAccuracy.high, 35),
    ]) {
      final p = await trySingleFix(t.$1, t.$2);
      if (_isValidPos(p)) {
        return p!;
      }
    }

    if (_isValidPos(cached)) {
      return cached!;
    }

    final last = await Geolocator.getLastKnownPosition();
    if (_isValidPos(last)) {
      return last!;
    }

    throw const PositionUpdateException(
      'No GPS position. Try again, use manual pincode, or on simulator set a custom location in device settings.',
    );
  }

  static Future<GuestDeliveryGpsResult> resolve() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const GuestDeliveryGpsFailure(
          'Location is turned off. Enable it in Settings, or enter your pincode or ZIP below.',
        );
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        return const GuestDeliveryGpsFailure(
          'Location permission is required to detect your area. You can allow it in Settings, or enter your pincode or ZIP below.',
        );
      }
      if (perm == LocationPermission.deniedForever) {
        return const GuestDeliveryGpsFailure(
          'Location access is disabled for this app. Turn it on in Settings, or enter your pincode or ZIP below.',
        );
      }
      if (perm == LocationPermission.unableToDetermine) {
        return const GuestDeliveryGpsFailure(
          "We couldn't start location. Try again, or enter your pincode or ZIP below.",
        );
      }

      final Position position;
      try {
        position = await _obtainPosition();
      } on LocationServiceDisabledException {
        return const GuestDeliveryGpsFailure(
          'Location services are off. Turn them on in Settings, or enter your pincode or ZIP below.',
        );
      } on PermissionDeniedException {
        return const GuestDeliveryGpsFailure(
          'Location permission is required. Allow access in Settings, or enter your pincode or ZIP below.',
        );
      } on TimeoutException {
        return const GuestDeliveryGpsFailure(
          'Location timed out. Try again near a window, or enter your pincode or ZIP below.',
        );
      } on PositionUpdateException catch (e) {
        final m = e.message;
        if (m != null && m.trim().isNotEmpty) {
          return GuestDeliveryGpsFailure(m.trim());
        }
        return const GuestDeliveryGpsFailure(
          "We couldn't get your position. Enter your pincode or ZIP below, or try again.",
        );
      }

      if (!position.latitude.isFinite || !position.longitude.isFinite) {
        return const GuestDeliveryGpsFailure(
          "We couldn't read a valid position. Please enter your pincode or ZIP below.",
        );
      }

      final List<Placemark> placeList;
      try {
        placeList = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
      } catch (_) {
        return const GuestDeliveryGpsFailure(
          "We couldn't look up your address. Enter your pincode or ZIP below.",
        );
      }
      if (placeList.isEmpty) {
        return const GuestDeliveryGpsFailure(
          "We couldn't read your area. Please enter your pincode or ZIP below.",
        );
      }
      final p = placeList.first;
      var country = p.isoCountryCode?.toUpperCase().trim() ?? '';
      if (country.isEmpty) {
        if (_latLngLooksLikeIndia(position.latitude, position.longitude)) {
          country = 'IN';
        } else if (_latLngLooksLikeContiguousUS(position.latitude, position.longitude)) {
          country = 'US';
        } else {
          return const GuestDeliveryGpsFailure(
            'We could not detect whether you are in India or the US. Choose a country and enter a pincode or ZIP below.',
          );
        }
      }

      final city = p.locality?.trim().isNotEmpty == true
          ? p.locality!.trim()
          : (p.subAdministrativeArea?.trim().isNotEmpty == true
              ? p.subAdministrativeArea!.trim()
              : p.administrativeArea?.trim());

      if (country == 'IN') {
        final pin = _normalizeIndiaPin(p.postalCode);
        if (pin == null) {
          return const GuestDeliveryGpsFailure(
            "We couldn't read your pincode. Enter your 6-digit pincode below.",
          );
        }
        return GuestDeliveryGpsSuccess(isIndia: true, postalCode: pin, city: city);
      }
      if (country == 'US') {
        final z = _normalizeUsZip(p.postalCode);
        if (z == null) {
          return const GuestDeliveryGpsFailure(
            "We couldn't read your ZIP code. Enter it below.",
          );
        }
        return GuestDeliveryGpsSuccess(isIndia: false, postalCode: z, city: city);
      }

      return const GuestDeliveryGpsFailure(
        'Delivery is set up for India and the US. Please choose your country and enter a pincode or ZIP below.',
      );
    } on LocationServiceDisabledException {
      return const GuestDeliveryGpsFailure(
        'Location services are off. Turn them on in Settings, or enter your pincode or ZIP below.',
      );
    } on PermissionDeniedException {
      return const GuestDeliveryGpsFailure(
        'Location permission is required. Allow access in Settings, or enter a pincode or ZIP below.',
      );
    } on TimeoutException {
      return const GuestDeliveryGpsFailure(
        'Location timed out. Try again or enter your pincode or ZIP below.',
      );
    } catch (e) {
      final msg = e.toString();
      if (msg.toLowerCase().contains('denied') || msg.toLowerCase().contains('permission')) {
        return const GuestDeliveryGpsFailure(
          'Location permission is required. Allow access in Settings, or enter a pincode or ZIP below.',
        );
      }
      if (msg.toLowerCase().contains('disabled') && msg.toLowerCase().contains('location')) {
        return const GuestDeliveryGpsFailure(
          'Location services are off. Turn them on in Settings, or enter a pincode or ZIP below.',
        );
      }
      return GuestDeliveryGpsFailure(
        _humanizeUnknownError(e),
      );
    }
  }

  /// Shorter, actionable copy instead of a generic "something went wrong".
  static String _humanizeUnknownError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('kclerr') || s.contains('locationunknown') || s.contains('location error')) {
      return "We couldn't get a GPS fix. Move to an open area, try again, or enter your pincode or ZIP below.";
    }
    if (s.contains('network') || s.contains('unavailable') || s.contains('failed')) {
      return 'Location services had a hiccup. Check your connection, try again, or enter your pincode or ZIP below.';
    }
    if (s.contains('activity')) {
      return 'App is not ready for location yet. Close and reopen the app, or enter your pincode or ZIP below.';
    }
    return "We couldn't get your position. On a simulator, set a custom location. Otherwise enter your pincode or ZIP below.";
  }

  static String? _normalizeIndiaPin(String? raw) {
    if (raw == null) return null;
    final d = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (d.length >= 6) return d.substring(0, 6);
    return null;
  }

  static String? _normalizeUsZip(String? raw) {
    if (raw == null) return null;
    var z = raw.trim();
    if (z.isEmpty) return null;
    if (RegExp(r'^\d{5}(-\d{4})?$').hasMatch(z)) {
      return z;
    }
    final digits = z.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length >= 5) {
      if (digits.length >= 9) {
        return '${digits.substring(0, 5)}-${digits.substring(5, 9)}';
      }
      return digits.substring(0, 5);
    }
    return null;
  }
}
