import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// [assets/env/app.env] `GOOGLE_MAPS_API_KEY` (or `VITE_GOOGLE_MAPS_API_KEY`) or `--dart-define=GOOGLE_MAPS_API_KEY=...`
String get resolvedGoogleMapsApiKey {
  if (dotenv.isInitialized) {
    final v = (dotenv.env['GOOGLE_MAPS_API_KEY'] ?? dotenv.env['VITE_GOOGLE_MAPS_API_KEY'])
            ?.trim() ??
        '';
    if (v.isNotEmpty) return v;
  }
  return const String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
}

class PlacePrediction {
  const PlacePrediction({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
  });

  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;
}

class PlaceAddressComponents {
  const PlaceAddressComponents({
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
  });

  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final String country;
}

/// Calls Google Places (legacy) JSON from the app using [resolvedGoogleMapsApiKey] only.
class GooglePlacesService {
  GooglePlacesService()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 12),
            receiveTimeout: const Duration(seconds: 12),
            validateStatus: (s) => s == 200,
          ),
        );

  final Dio _dio;

  static String? iso2ForAddressCountry(String country) {
    final c = country.trim().toLowerCase();
    if (c == 'india' || c == 'in') return 'in';
    if (c == 'united states' || c == 'us' || c == 'usa' || c == 'u.s.') return 'us';
    return null;
  }

  List<PlacePrediction> _parsePredictions(Object? data) {
    if (data is! Map) return [];
    final list = data['predictions'] as List<dynamic>? ?? [];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final structured = m['structured_formatting'] as Map<String, dynamic>?;
      return PlacePrediction(
        placeId: m['place_id'] as String? ?? '',
        description: m['description'] as String? ?? '',
        mainText: structured?['main_text'] as String?,
        secondaryText: structured?['secondary_text'] as String?,
      );
    }).where((p) => p.placeId.isNotEmpty).toList();
  }

  Future<List<PlacePrediction>> autocomplete(
    String input, {
    String? countryIso2,
  }) async {
    final q = input.trim();
    if (q.length < 2) return [];
    if (resolvedGoogleMapsApiKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('[Places] Set GOOGLE_MAPS_API_KEY in assets/env/app.env');
      }
      return [];
    }
    try {
      final query = <String, dynamic>{
        'input': q,
        'key': resolvedGoogleMapsApiKey,
      };
      if (countryIso2 != null && countryIso2.isNotEmpty) {
        query['components'] = 'country:${countryIso2.toLowerCase()}';
      }
      final res = await _dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: query,
      );
      final data = res.data;
      if (data == null) return [];
      final status = data['status'] as String? ?? '';
      if (kDebugMode && status != 'OK' && status != 'ZERO_RESULTS') {
        final err = data['error_message'] as String?;
        debugPrint('[Places] status=$status err=$err');
      }
      if (status != 'OK' && status != 'ZERO_RESULTS') return [];
      return _parsePredictions(data);
    } catch (e) {
      if (kDebugMode) debugPrint('[Places] autocomplete: $e');
      return [];
    }
  }

  Future<PlaceAddressComponents?> placeDetails(String placeId) async {
    if (placeId.isEmpty) return null;
    if (resolvedGoogleMapsApiKey.isEmpty) return null;
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': resolvedGoogleMapsApiKey,
          'fields': 'address_components,formatted_address',
        },
      );
      final data = res.data;
      if (data == null) return null;
      if ((data['status'] as String?) != 'OK') return null;
      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) return null;
      return _parseComponents(
        result['address_components'] as List<dynamic>?,
        result['formatted_address'] as String?,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Places] details: $e');
      return null;
    }
  }

  PlaceAddressComponents? _parseComponents(
    List<dynamic>? components,
    String? formatted,
  ) {
    if (components == null) return null;

    String get(String type) {
      for (final c in components) {
        final m = c as Map<String, dynamic>;
        final types = m['types'] as List<dynamic>?;
        if (types == null) continue;
        if (types.contains(type)) {
          return m['long_name'] as String? ?? '';
        }
      }
      return '';
    }

    String getShort(String type) {
      for (final c in components) {
        final m = c as Map<String, dynamic>;
        final types = m['types'] as List<dynamic>?;
        if (types == null) continue;
        if (types.contains(type)) {
          return m['short_name'] as String? ?? '';
        }
      }
      return '';
    }

    final countryCode = getShort('country');
    final streetNum = get('street_number');
    final route = get('route');
    final postalCode = get('postal_code');
    final postalSuffix = get('postal_code_suffix');
    var pin = '';
    if (countryCode == 'US') {
      if (postalCode.isNotEmpty) {
        pin = postalSuffix.isNotEmpty ? '$postalCode-$postalSuffix' : postalCode;
      }
    } else {
      pin = [postalCode, postalSuffix].where((e) => e.isNotEmpty).join('-');
    }
    var line = [streetNum, route].where((e) => e.isNotEmpty).join(' ');
    if (line.isEmpty && formatted != null) {
      line = formatted.split(',').first.trim();
    }
    if (line.isEmpty) {
      return null;
    }
    return PlaceAddressComponents(
      addressLine: line,
      city: get('locality').isNotEmpty
          ? get('locality')
          : (get('sublocality').isNotEmpty
              ? get('sublocality')
              : get('administrative_area_level_2')),
      state: get('administrative_area_level_1'),
      pincode: pin,
      country: get('country').isNotEmpty ? get('country') : countryCode,
    );
  }
}
