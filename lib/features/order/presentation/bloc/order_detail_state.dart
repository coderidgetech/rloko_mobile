part of 'order_detail_bloc.dart';

sealed class OrderDetailState extends Equatable {
  const OrderDetailState();
  @override
  List<Object?> get props => [];
}

final class OrderDetailInitial extends OrderDetailState {
  const OrderDetailInitial();
}

final class OrderDetailLoading extends OrderDetailState {
  const OrderDetailLoading();
}

final class OrderDetailLoaded extends OrderDetailState {
  const OrderDetailLoaded({
    required this.order,
    this.trackingUpdates = const [],
  });
  final OrderEntity order;
  final List<OrderTrackingUpdateEntity> trackingUpdates;
  @override
  List<Object?> get props => [order.id];
}

final class OrderDetailError extends OrderDetailState {
  const OrderDetailError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

final class OrderDetailCancelSuccess extends OrderDetailState {
  const OrderDetailCancelSuccess();
}
