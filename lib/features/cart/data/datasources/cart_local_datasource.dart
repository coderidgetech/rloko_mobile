import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/cart_entity.dart';
import '../../domain/entities/cart_item_entity.dart';

const _key = 'rloco_cart';
const _version = '1.0';

/// Guest cart in local storage (like web app localStorage). Merge to API on login.
class CartLocalDataSource {
  CartLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  CartEntity getCart() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      return CartEntity(
        id: 'guest',
        userId: '',
        items: [],
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>?;
      if (decoded == null || decoded['version'] != _version) return _empty();
      final list = decoded['items'];
      if (list is! List) return _empty();
      final items = <CartItemEntity>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          items.add(CartItemEntity(
            productId: e['product_id']?.toString() ?? '',
            productName: e['product_name'] as String? ?? '',
            image: e['image'] as String? ?? '',
            price: (e['price'] is num) ? (e['price'] as num).toDouble() : 0.0,
            priceInr: e['price_inr'] != null
                ? (e['price_inr'] as num).toDouble()
                : null,
            size: e['size'] as String? ?? '',
            quantity: e['quantity'] is int ? e['quantity'] as int : 0,
          ));
        }
      }
      return CartEntity(
        id: 'guest',
        userId: '',
        items: items,
        updatedAt: decoded['updated_at'] as String? ?? DateTime.now().toUtc().toIso8601String(),
      );
    } catch (_) {
      return _empty();
    }
  }

  CartEntity _empty() => CartEntity(
        id: 'guest',
        userId: '',
        items: [],
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

  Future<void> saveCart(CartEntity cart) async {
    final list = cart.items
        .map((e) => {
              'product_id': e.productId,
              'product_name': e.productName,
              'image': e.image,
              'price': e.price,
              if (e.priceInr != null) 'price_inr': e.priceInr,
              'size': e.size,
              'quantity': e.quantity,
            })
        .toList();
    await _prefs.setString(
      _key,
      jsonEncode({
        'version': _version,
        'items': list,
        'updated_at': cart.updatedAt,
      }),
    );
  }

  Future<void> clearCart() async {
    await _prefs.remove(_key);
  }

  List<CartItemEntity> getItems() => getCart().items;
}
