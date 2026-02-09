import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/usecases/order_usecases.dart';

part 'order_detail_event.dart';
part 'order_detail_state.dart';

class OrderDetailBloc extends Bloc<OrderDetailEvent, OrderDetailState> {
  OrderDetailBloc({
    required GetOrderByIdUseCase getOrderByIdUseCase,
    required GetOrderTrackingUseCase getOrderTrackingUseCase,
    required CancelOrderUseCase cancelOrderUseCase,
  })  : _getOrderByIdUseCase = getOrderByIdUseCase,
        _getOrderTrackingUseCase = getOrderTrackingUseCase,
        _cancelOrderUseCase = cancelOrderUseCase,
        super(const OrderDetailInitial()) {
    on<OrderDetailLoadRequested>(_onLoad);
    on<OrderDetailCancelRequested>(_onCancel);
  }

  final GetOrderByIdUseCase _getOrderByIdUseCase;
  final GetOrderTrackingUseCase _getOrderTrackingUseCase;
  final CancelOrderUseCase _cancelOrderUseCase;

  Future<void> _onLoad(
    OrderDetailLoadRequested event,
    Emitter<OrderDetailState> emit,
  ) async {
    emit(const OrderDetailLoading());
    try {
      final order = await _getOrderByIdUseCase(event.orderId);
      List<OrderTrackingUpdateEntity> tracking = [];
      try {
        tracking = await _getOrderTrackingUseCase(event.orderId);
      } catch (_) {}
      emit(OrderDetailLoaded(order: order, trackingUpdates: tracking));
    } catch (e) {
      emit(OrderDetailError(e.toString()));
    }
  }

  Future<void> _onCancel(
    OrderDetailCancelRequested event,
    Emitter<OrderDetailState> emit,
  ) async {
    final current = state;
    if (current is! OrderDetailLoaded) return;
    try {
      await _cancelOrderUseCase(current.order.id, reason: event.reason);
      emit(const OrderDetailCancelSuccess());
    } catch (e) {
      emit(OrderDetailError(e.toString()));
    }
  }
}
