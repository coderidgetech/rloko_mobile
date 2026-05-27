import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../dto/product_dto.dart';

const _homeKey = 'rloco_home_products';
const _ttlSeconds = 1800; // 30 min

/// Caches home product sections (featured, new arrivals, on-sale) in SharedPreferences.
class ProductLocalDataSource {
  ProductLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  /// Returns cached products keyed by section name, or null if cache is missing/expired.
  Map<String, List<ProductDto>>? getCachedHomeProducts() {
    final raw = _prefs.getString(_homeKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = decoded['timestamp'] as int? ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch ~/ 1000 - ts;
      if (age > _ttlSeconds) return null;
      final sections = decoded['sections'] as Map<String, dynamic>?;
      if (sections == null) return null;
      return sections.map((key, value) {
        final list = (value as List<dynamic>)
            .map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
            .toList();
        return MapEntry(key, list);
      });
    } catch (_) {
      return null;
    }
  }

  /// Cache raw product data (List of json maps) per section.
  Future<void> cacheHomeProducts(Map<String, List<Map<String, dynamic>>> rawSections) async {
    final payload = jsonEncode({
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'sections': rawSections,
    });
    await _prefs.setString(_homeKey, payload);
  }

  /// Returns cached products for a single section, or null if missing/expired.
  List<ProductDto>? getCachedSection(String sectionKey) =>
      getCachedHomeProducts()?[sectionKey];

  /// Writes a single section into the cache without invalidating others.
  Future<void> cacheSection(String sectionKey, List<Map<String, dynamic>> rawList) async {
    final raw = _prefs.getString(_homeKey);
    Map<String, dynamic> existing = {};
    if (raw != null) {
      try {
        existing = (jsonDecode(raw) as Map<String, dynamic>)['sections']
                as Map<String, dynamic>? ??
            {};
      } catch (_) {}
    }
    existing[sectionKey] = rawList;
    await cacheHomeProducts(
      existing.map((k, v) {
        final list = (v as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        return MapEntry(k, list);
      }),
    );
  }

  Future<void> clearCache() async => _prefs.remove(_homeKey);
}
