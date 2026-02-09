import 'package:equatable/equatable.dart';

import 'cart_item_entity.dart';

class CartEntity extends Equatable {
  const CartEntity({
    required this.id,
    required this.userId,
    required this.items,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final List<CartItemEntity> items;
  final String updatedAt;

  int get itemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props => [id, items, updatedAt];
}
