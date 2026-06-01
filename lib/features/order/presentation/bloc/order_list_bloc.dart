import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_filter.dart';
import '../../domain/usecases/order_usecases.dart';

part 'order_list_event.dart';
part 'order_list_state.dart';

const _kPageSize = 20;

class OrderListBloc extends Bloc<OrderListEvent, OrderListState> {
  OrderListBloc({
    required GetOrdersUseCase getOrdersUseCase,
  })  : _getOrdersUseCase = getOrdersUseCase,
        super(const OrderListInitial()) {
    on<OrderListLoadRequested>(_onLoad, transformer: restartable());
    on<OrderListLoadMore>(_onLoadMore, transformer: droppable());
  }

  final GetOrdersUseCase _getOrdersUseCase;

  List<OrderEntity> _applyFilter(
    List<OrderEntity> orders,
    OrderListFilter filter,
  ) {
    switch (filter) {
      case OrderListFilter.active:
        return orders
            .where(
              (o) =>
                  o.status == 'pending' ||
                  o.status == 'processing' ||
                  o.status == 'shipped',
            )
            .toList();
      case OrderListFilter.completed:
        return orders
            .where(
              (o) => o.status == 'delivered' || o.status == 'cancelled',
            )
            .toList();
      case OrderListFilter.all:
        return orders;
    }
  }

  Future<void> _onLoad(
    OrderListLoadRequested event,
    Emitter<OrderListState> emit,
  ) async {
    emit(const OrderListLoading());
    try {
      final result = await _getOrdersUseCase(
        limit: _kPageSize,
        skip: 0,
        status: null,
      );
      final orders = _applyFilter(result.orders, event.filter);
      if (kDebugMode) {
        debugPrint(
          '[OrderListBloc] Loaded ${orders.length} orders, total=${result.total}',
        );
      }
      emit(OrderListLoaded(
        orders: orders,
        total: result.total,
        filter: event.filter,
        hasMore: result.orders.length >= _kPageSize,
        page: 1,
      ));
    } catch (e, st) {
      final api = getApiException(e);
      if (kDebugMode) {
        debugPrint('[OrderListBloc] Load failed: $e');
        debugPrint('[OrderListBloc] Stack: $st');
      }
      if (api?.statusCode == 401) {
        emit(const OrderListError('Sign in to view your orders'));
      } else {
        emit(OrderListError(api?.message ?? e.toString()));
      }
    }
  }

  Future<void> _onLoadMore(
    OrderListLoadMore event,
    Emitter<OrderListState> emit,
  ) async {
    final current = state;
    if (current is! OrderListLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;

    emit(OrderListLoaded(
      orders: current.orders,
      total: current.total,
      filter: current.filter,
      hasMore: current.hasMore,
      page: current.page,
      isLoadingMore: true,
    ));

    try {
      final result = await _getOrdersUseCase(
        limit: _kPageSize,
        skip: current.page * _kPageSize,
        status: null,
      );
      final newOrders = _applyFilter(result.orders, current.filter);
      if (kDebugMode) {
        debugPrint(
          '[OrderListBloc] LoadMore page=${current.page + 1}, got ${newOrders.length} more orders',
        );
      }
      emit(OrderListLoaded(
        orders: [...current.orders, ...newOrders],
        total: result.total,
        filter: current.filter,
        hasMore: result.orders.length >= _kPageSize,
        page: current.page + 1,
      ));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[OrderListBloc] LoadMore failed: $e');
      }
      // Restore previous state without isLoadingMore
      emit(OrderListLoaded(
        orders: current.orders,
        total: current.total,
        filter: current.filter,
        hasMore: current.hasMore,
        page: current.page,
      ));
    }
  }
}
