import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/order_usecases.dart';

part 'order_list_event.dart';
part 'order_list_state.dart';

class OrderListBloc extends Bloc<OrderListEvent, OrderListState> {
  OrderListBloc({
    required GetOrdersUseCase getOrdersUseCase,
  })  : _getOrdersUseCase = getOrdersUseCase,
        super(const OrderListInitial()) {
    on<OrderListLoadRequested>(_onLoad);
  }

  final GetOrdersUseCase _getOrdersUseCase;

  Future<void> _onLoad(
    OrderListLoadRequested event,
    Emitter<OrderListState> emit,
  ) async {
    emit(const OrderListLoading());
    try {
      final result = await _getOrdersUseCase(
        limit: event.limit,
        skip: event.skip,
        status: null,
      );
      List<OrderEntity> orders = result.orders;
      switch (event.filter) {
        case OrderListFilter.active:
          orders = orders
              .where((o) =>
                  o.status == 'pending' ||
                  o.status == 'processing' ||
                  o.status == 'shipped')
              .toList();
          break;
        case OrderListFilter.completed:
          orders = orders
              .where((o) => o.status == 'delivered' || o.status == 'cancelled')
              .toList();
          break;
        case OrderListFilter.all:
          break;
      }
      if (kDebugMode) {
        debugPrint('[OrderListBloc] Loaded ${orders.length} orders, total=${result.total}');
      }
      emit(OrderListLoaded(
        orders: orders,
        total: result.total,
        filter: event.filter,
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
}
