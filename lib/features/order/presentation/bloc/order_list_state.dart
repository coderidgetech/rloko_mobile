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
    this.hasMore = false,
    this.page = 1,
    this.isLoadingMore = false,
  });
  final List<OrderEntity> orders;
  final int total;
  final OrderListFilter filter;
  final bool hasMore;
  final int page;
  final bool isLoadingMore;
  @override
  List<Object?> get props => [orders, total, filter, hasMore, page, isLoadingMore];
}

final class OrderListError extends OrderListState {
  const OrderListError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
