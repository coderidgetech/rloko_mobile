part of 'order_list_bloc.dart';

sealed class OrderListEvent extends Equatable {
  const OrderListEvent();
  @override
  List<Object?> get props => [];
}

final class OrderListLoadRequested extends OrderListEvent {
  const OrderListLoadRequested({
    this.limit = 20,
    this.skip = 0,
    this.filter = OrderListFilter.all,
  });
  final int limit;
  final int skip;
  final OrderListFilter filter;
  @override
  List<Object?> get props => [limit, skip, filter];
}

final class OrderListLoadMore extends OrderListEvent {
  const OrderListLoadMore();
}
