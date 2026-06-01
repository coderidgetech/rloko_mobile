part of 'return_order_cubit.dart';

abstract class ReturnOrderState extends Equatable {
  const ReturnOrderState();

  @override
  List<Object?> get props => [];
}

class ReturnOrderInitial extends ReturnOrderState {}

class ReturnOrderLoading extends ReturnOrderState {}

class ReturnOrderLoaded extends ReturnOrderState {
  const ReturnOrderLoaded(this.returns);

  final List<ReturnEntity> returns;

  @override
  List<Object?> get props => [returns];
}

class ReturnOrderError extends ReturnOrderState {
  const ReturnOrderError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ReturnOrderCreateSuccess extends ReturnOrderState {}
