import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/cart_local_datasource.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/usecases/cart_usecases.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({
    required GetCartUseCase getCartUseCase,
    required AddCartItemUseCase addCartItemUseCase,
    required UpdateCartItemUseCase updateCartItemUseCase,
    required RemoveCartItemUseCase removeCartItemUseCase,
    required ClearCartUseCase clearCartUseCase,
    required DioClient dioClient,
    required CartLocalDataSource localCart,
  })  : _getCart = getCartUseCase,
        _addItem = addCartItemUseCase,
        _updateItem = updateCartItemUseCase,
        _removeItem = removeCartItemUseCase,
        _clearCart = clearCartUseCase,
        _dioClient = dioClient,
        _localCart = localCart,
        super(const CartInitial()) {
    on<CartLoadRequested>(_onLoad);
    on<CartAddItemRequested>(_onAddItem);
    on<CartUpdateItemRequested>(_onUpdateItem);
    on<CartRemoveItemRequested>(_onRemoveItem);
    on<CartClearRequested>(_onClear);
    on<CartMergeGuestCartRequested>(_onMergeGuestCart);
  }

  final GetCartUseCase _getCart;
  final AddCartItemUseCase _addItem;
  final UpdateCartItemUseCase _updateItem;
  final RemoveCartItemUseCase _removeItem;
  final ClearCartUseCase _clearCart;
  final DioClient _dioClient;
  final CartLocalDataSource _localCart;

  Future<void> _onLoad(CartLoadRequested event, Emitter<CartState> emit) async {
    final token = await _dioClient.getToken();
    if (token == null || token.isEmpty) {
      final cart = _localCart.getCart();
      emit(CartLoaded(cart));
      return;
    }
    emit(const CartLoading());
    try {
      final cart = await _getCart();
      emit(CartLoaded(cart));
    } catch (e) {
      final api = getApiException(e);
      if (api?.statusCode == 401) {
        final cart = _localCart.getCart();
        emit(CartLoaded(cart));
      } else {
        emit(CartError(api?.message ?? e.toString()));
      }
    }
  }

  Future<void> _onAddItem(CartAddItemRequested event, Emitter<CartState> emit) async {
    final token = await _dioClient.getToken();
    if (token == null || token.isEmpty) {
      _addToGuestCart(event.item);
      final cart = _localCart.getCart();
      emit(CartLoaded(cart));
      return;
    }
    try {
      await _addItem(event.item);
      add(const CartLoadRequested());
    } catch (e) {
      final api = getApiException(e);
      if (api?.statusCode == 401) {
        _addToGuestCart(event.item);
        final cart = _localCart.getCart();
        emit(CartLoaded(cart));
      } else {
        emit(CartError(api?.message ?? e.toString()));
      }
    }
  }

  void _addToGuestCart(CartItemEntity item) {
    final cart = _localCart.getCart();
    final items = List<CartItemEntity>.from(cart.items);
    final idx = items.indexWhere(
        (i) => i.productId == item.productId && i.size == item.size);
    if (idx >= 0) {
      items[idx] = CartItemEntity(
        productId: items[idx].productId,
        productName: items[idx].productName,
        image: items[idx].image,
        price: items[idx].price,
        priceInr: items[idx].priceInr,
        size: items[idx].size,
        quantity: items[idx].quantity + item.quantity,
      );
    } else {
      items.add(item);
    }
    _localCart.saveCart(CartEntity(
      id: 'guest',
      userId: '',
      items: items,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    ));
  }

  Future<void> _onUpdateItem(CartUpdateItemRequested event, Emitter<CartState> emit) async {
    final token = await _dioClient.getToken();
    if (token == null || token.isEmpty) {
      _updateGuestCart(event.productId, event.size, event.quantity);
      final cart = _localCart.getCart();
      emit(CartLoaded(cart));
      return;
    }
    try {
      await _updateItem(event.productId, event.size, event.quantity);
      add(const CartLoadRequested());
    } catch (e) {
      final api = getApiException(e);
      if (api?.statusCode == 401) {
        _updateGuestCart(event.productId, event.size, event.quantity);
        final cart = _localCart.getCart();
        emit(CartLoaded(cart));
      } else {
        emit(CartError(api?.message ?? e.toString()));
      }
    }
  }

  void _updateGuestCart(String productId, String size, int quantity) {
    final cart = _localCart.getCart();
    if (quantity <= 0) {
      final items = cart.items
          .where((i) => !(i.productId == productId && i.size == size))
          .toList();
      _localCart.saveCart(CartEntity(
        id: 'guest',
        userId: '',
        items: items,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      ));
      return;
    }
    final items = cart.items.map((i) {
      if (i.productId == productId && i.size == size) {
        return CartItemEntity(
          productId: i.productId,
          productName: i.productName,
          image: i.image,
          price: i.price,
          priceInr: i.priceInr,
          size: i.size,
          quantity: quantity,
        );
      }
      return i;
    }).toList();
    _localCart.saveCart(CartEntity(
      id: 'guest',
      userId: '',
      items: items,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    ));
  }

  Future<void> _onRemoveItem(CartRemoveItemRequested event, Emitter<CartState> emit) async {
    final token = await _dioClient.getToken();
    if (token == null || token.isEmpty) {
      _updateGuestCart(event.productId, event.size, 0);
      final cart = _localCart.getCart();
      emit(CartLoaded(cart));
      return;
    }
    try {
      await _removeItem(event.productId, event.size);
      add(const CartLoadRequested());
    } catch (e) {
      final api = getApiException(e);
      if (api?.statusCode == 401) {
        _updateGuestCart(event.productId, event.size, 0);
        final cart = _localCart.getCart();
        emit(CartLoaded(cart));
      } else {
        emit(CartError(api?.message ?? e.toString()));
      }
    }
  }

  Future<void> _onClear(CartClearRequested event, Emitter<CartState> emit) async {
    final token = await _dioClient.getToken();
    if (token == null || token.isEmpty) {
      await _localCart.clearCart();
      emit(CartLoaded(_localCart.getCart()));
      return;
    }
    try {
      await _clearCart();
      add(const CartLoadRequested());
    } catch (e) {
      final api = getApiException(e);
      if (api?.statusCode == 401) {
        await _localCart.clearCart();
        emit(CartLoaded(_localCart.getCart()));
      } else {
        emit(CartError(api?.message ?? e.toString()));
      }
    }
  }

  Future<void> _onMergeGuestCart(CartMergeGuestCartRequested event, Emitter<CartState> emit) async {
    final items = _localCart.getItems();
    if (items.isEmpty) {
      add(const CartLoadRequested());
      return;
    }
    emit(const CartLoading());
    for (final item in items) {
      try {
        await _addItem(item);
      } catch (_) {}
    }
    await _localCart.clearCart();
    add(const CartLoadRequested());
  }
}
