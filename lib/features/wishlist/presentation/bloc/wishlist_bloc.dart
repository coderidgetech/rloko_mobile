import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/wishlist_local_datasource.dart';
import '../../domain/entities/wishlist_entity.dart';
import '../../domain/usecases/wishlist_usecases.dart';

part 'wishlist_event.dart';
part 'wishlist_state.dart';

class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  WishlistBloc({
    required GetWishlistUseCase getWishlistUseCase,
    required AddWishlistItemUseCase addWishlistItemUseCase,
    required RemoveWishlistItemUseCase removeWishlistItemUseCase,
    required DioClient dioClient,
    required WishlistLocalDataSource localWishlist,
  })  : _getWishlist = getWishlistUseCase,
        _addItem = addWishlistItemUseCase,
        _removeItem = removeWishlistItemUseCase,
        _dioClient = dioClient,
        _localWishlist = localWishlist,
        super(const WishlistInitial()) {
    on<WishlistLoadRequested>(_onLoad);
    on<WishlistAddItemRequested>(_onAddItem);
    on<WishlistRemoveItemRequested>(_onRemoveItem);
    on<WishlistMergeGuestRequested>(_onMergeGuest);
  }

  final GetWishlistUseCase _getWishlist;
  final AddWishlistItemUseCase _addItem;
  final RemoveWishlistItemUseCase _removeItem;
  final DioClient _dioClient;
  final WishlistLocalDataSource _localWishlist;

  List<WishlistEntity> get _guestItems => _localWishlist.getItems();

  void _saveGuest(List<WishlistEntity> items) => _localWishlist.saveItems(items);

  Future<void> _fetchAndEmit(Emitter<WishlistState> emit) async {
    final token = await _dioClient.getToken();
    if (token == null || token.isEmpty) {
      emit(WishlistLoaded(List.from(_guestItems)));
      return;
    }
    emit(const WishlistLoading());
    try {
      final list = await _getWishlist();
      emit(WishlistLoaded(list));
    } catch (e) {
      final api = getApiException(e);
      if (api?.statusCode == 401) {
        emit(WishlistLoaded(List.from(_guestItems)));
      } else {
        emit(WishlistError(api?.message ?? e.toString()));
      }
    }
  }

  Future<void> _onLoad(WishlistLoadRequested event, Emitter<WishlistState> emit) async {
    await _fetchAndEmit(emit);
  }

  Future<void> _onAddItem(WishlistAddItemRequested event, Emitter<WishlistState> emit) async {
    final token = await _dioClient.getToken();
    if (token == null || token.isEmpty) {
      final current = _guestItems;
      if (current.any((i) => i.productId == event.productId)) return;
      final updated = [
        ...current,
        WishlistEntity(
          id: 'guest-${event.productId}',
          userId: '',
          productId: event.productId,
          createdAt: DateTime.now().toUtc().toIso8601String(),
          productName: event.productName,
          productImage: event.productImage,
          productPrice: event.productPrice,
        ),
      ];
      _saveGuest(updated);
      emit(WishlistLoaded(updated));
      return;
    }
    try {
      await _addItem(event.productId);
      await _fetchAndEmit(emit);
    } catch (e) {
      final api = getApiException(e);
      if (api?.statusCode == 401) {
        final current = _guestItems;
        if (!current.any((i) => i.productId == event.productId)) {
          final updated = [
            ...current,
            WishlistEntity(
              id: 'guest-${event.productId}',
              userId: '',
              productId: event.productId,
              createdAt: DateTime.now().toUtc().toIso8601String(),
              productName: event.productName,
              productImage: event.productImage,
              productPrice: event.productPrice,
            ),
          ];
          _saveGuest(updated);
          emit(WishlistLoaded(updated));
        }
      } else {
        emit(WishlistError(api?.message ?? e.toString()));
      }
    }
  }

  Future<void> _onRemoveItem(WishlistRemoveItemRequested event, Emitter<WishlistState> emit) async {
    final token = await _dioClient.getToken();
    if (token == null || token.isEmpty) {
      final updated = _guestItems.where((i) => i.productId != event.productId).toList();
      _saveGuest(updated);
      emit(WishlistLoaded(updated));
      return;
    }
    try {
      await _removeItem(event.productId);
      await _fetchAndEmit(emit);
    } catch (e) {
      final api = getApiException(e);
      if (api?.statusCode == 401) {
        final updated = _guestItems.where((i) => i.productId != event.productId).toList();
        _saveGuest(updated);
        emit(WishlistLoaded(updated));
      } else {
        emit(WishlistError(api?.message ?? e.toString()));
      }
    }
  }

  Future<void> _onMergeGuest(WishlistMergeGuestRequested event, Emitter<WishlistState> emit) async {
    final items = _guestItems;
    if (items.isEmpty) {
      await _fetchAndEmit(emit);
      return;
    }
    final synced = <String>[];
    for (final item in items) {
      try {
        await _addItem(item.productId);
        synced.add(item.productId);
      } catch (e) {
        if (kDebugMode) debugPrint('[WishlistBloc] guest item migration skipped: $e');
      }
    }
    // Clear only successfully synced items
    final remaining = items.where((i) => !synced.contains(i.productId)).toList();
    if (remaining.isEmpty) {
      _localWishlist.clearItems();
    } else {
      _saveGuest(remaining);
    }
    await _fetchAndEmit(emit);
  }
}
