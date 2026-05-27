import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/network/dio_client.dart';
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
  })  : _getWishlist = getWishlistUseCase,
        _addItem = addWishlistItemUseCase,
        _removeItem = removeWishlistItemUseCase,
        _dioClient = dioClient,
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

  /// In-memory guest wishlist (like web app). Merged to API on login.
  final List<WishlistEntity> _guestItems = [];

  Future<void> _onLoad(WishlistLoadRequested event, Emitter<WishlistState> emit) async {
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

  Future<void> _onAddItem(WishlistAddItemRequested event, Emitter<WishlistState> emit) async {
    final token = await _dioClient.getToken();
    if (token == null || token.isEmpty) {
      if (_guestItems.any((i) => i.productId == event.productId)) return;
      _guestItems.add(WishlistEntity(
        id: 'guest-${event.productId}',
        userId: '',
        productId: event.productId,
        createdAt: DateTime.now().toUtc().toIso8601String(),
        productName: event.productName,
        productImage: event.productImage,
        productPrice: event.productPrice,
      ));
      emit(WishlistLoaded(List.from(_guestItems)));
      return;
    }
    try {
      await _addItem(event.productId);
      add(const WishlistLoadRequested());
    } catch (e) {
      final api = getApiException(e);
      if (api?.statusCode == 401) {
        if (!_guestItems.any((i) => i.productId == event.productId)) {
          _guestItems.add(WishlistEntity(
            id: 'guest-${event.productId}',
            userId: '',
            productId: event.productId,
            createdAt: DateTime.now().toUtc().toIso8601String(),
            productName: event.productName,
            productImage: event.productImage,
            productPrice: event.productPrice,
          ));
        }
        emit(WishlistLoaded(List.from(_guestItems)));
      } else {
        emit(WishlistError(api?.message ?? e.toString()));
      }
    }
  }

  Future<void> _onRemoveItem(WishlistRemoveItemRequested event, Emitter<WishlistState> emit) async {
    final token = await _dioClient.getToken();
    if (token == null || token.isEmpty) {
      _guestItems.removeWhere((i) => i.productId == event.productId);
      emit(WishlistLoaded(List.from(_guestItems)));
      return;
    }
    try {
      await _removeItem(event.productId);
      add(const WishlistLoadRequested());
    } catch (e) {
      final api = getApiException(e);
      if (api?.statusCode == 401) {
        _guestItems.removeWhere((i) => i.productId == event.productId);
        emit(WishlistLoaded(List.from(_guestItems)));
      } else {
        emit(WishlistError(api?.message ?? e.toString()));
      }
    }
  }

  Future<void> _onMergeGuest(WishlistMergeGuestRequested event, Emitter<WishlistState> emit) async {
    if (_guestItems.isEmpty) {
      add(const WishlistLoadRequested());
      return;
    }
    for (final item in List<WishlistEntity>.from(_guestItems)) {
      try {
        await _addItem(item.productId);
      } catch (e) {
        if (kDebugMode) debugPrint('[WishlistBloc] guest item migration skipped: $e');
      }
    }
    _guestItems.clear();
    add(const WishlistLoadRequested());
  }
}
