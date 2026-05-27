import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../features/return_order/domain/usecases/create_return_usecase.dart';
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
    required CreateReturnUseCase createReturnUseCase,
  })  : _getOrderByIdUseCase = getOrderByIdUseCase,
        _getOrderTrackingUseCase = getOrderTrackingUseCase,
        _cancelOrderUseCase = cancelOrderUseCase,
        _createReturnUseCase = createReturnUseCase,
        super(const OrderDetailInitial()) {
    on<OrderDetailLoadRequested>(_onLoad);
    on<OrderDetailCancelRequested>(_onCancel);
    on<OrderDetailReturnRequested>(_onReturn);
  }

  final GetOrderByIdUseCase _getOrderByIdUseCase;
  final GetOrderTrackingUseCase _getOrderTrackingUseCase;
  final CancelOrderUseCase _cancelOrderUseCase;
  final CreateReturnUseCase _createReturnUseCase;

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
      } catch (e) {
        if (kDebugMode) debugPrint('[OrderDetailBloc] tracking fetch skipped: $e');
      }
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

  Future<void> _onReturn(
    OrderDetailReturnRequested event,
    Emitter<OrderDetailState> emit,
  ) async {
    final current = state;
    if (current is! OrderDetailLoaded) return;
    try {
      await _createReturnUseCase(
        orderId: current.order.id,
        items: event.items,
        reason: event.reason,
        description: event.description,
      );
      emit(const OrderDetailReturnSuccess());
    } catch (e) {
      emit(OrderDetailReturnError(e.toString()));
      // Restore loaded state so the page doesn't break
      emit(current);
    }
  }
}
