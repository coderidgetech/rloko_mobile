part of 'order_detail_bloc.dart';

sealed class OrderDetailEvent extends Equatable {
  const OrderDetailEvent();
  @override
  List<Object?> get props => [];
}

final class OrderDetailLoadRequested extends OrderDetailEvent {
  const OrderDetailLoadRequested(this.orderId);
  final String orderId;
  @override
  List<Object?> get props => [orderId];
}

final class OrderDetailCancelRequested extends OrderDetailEvent {
  const OrderDetailCancelRequested({this.reason});
  final String? reason;
  @override
  List<Object?> get props => [reason];
}

final class OrderDetailReturnRequested extends OrderDetailEvent {
  const OrderDetailReturnRequested({
    required this.items,
    required this.reason,
    this.description = '',
  });
  final List<Map<String, dynamic>> items;
  final String reason;
  final String description;
  @override
  List<Object?> get props => [reason];
}
