import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/wishlist_entity.dart';

class WishlistLocalDataSource {
  WishlistLocalDataSource(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'guest_wishlist';

  List<WishlistEntity> getItems() {
    final raw = _prefs.getStringList(_key) ?? [];
    return raw.map((s) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        return WishlistEntity(
          id: 'guest-${m['productId'] as String}',
          userId: '',
          productId: m['productId'] as String,
          createdAt: m['createdAt'] as String? ?? DateTime.now().toUtc().toIso8601String(),
          productName: m['productName'] as String?,
          productImage: m['productImage'] as String?,
          productPrice: (m['productPrice'] as num?)?.toDouble(),
        );
      } catch (_) {
        return null;
      }
    }).whereType<WishlistEntity>().toList();
  }

  void saveItems(List<WishlistEntity> items) {
    final raw = items
        .map((e) => jsonEncode({
              'productId': e.productId,
              'productName': e.productName,
              'productImage': e.productImage,
              'productPrice': e.productPrice,
              'createdAt': e.createdAt,
            }))
        .toList();
    _prefs.setStringList(_key, raw);
  }

  void clearItems() => _prefs.remove(_key);
}
