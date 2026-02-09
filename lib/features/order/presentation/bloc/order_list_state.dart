part of 'order_list_bloc.dart';

sealed class OrderListState extends Equatable {
  const OrderListState();
  @override
  List<Object?> get props => [];
}

final class OrderListInitial extends OrderListState {
  const OrderListInitial();
}

final class OrderListLoading extends OrderListState {
  const OrderListLoading();
}

final class OrderListLoaded extends OrderListState {
  const OrderListLoaded({
    required this.orders,
    required this.total,
    required this.filter,
  });
  final List<OrderEntity> orders;
  final int total;
  final OrderListFilter filter;
  @override
  List<Object?> get props => [orders.length, total, filter];
}

final class OrderListError extends OrderListState {
  const OrderListError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
