part of 'shipping_methods_cubit.dart';

abstract class ShippingMethodsState extends Equatable {
  const ShippingMethodsState();

  @override
  List<Object?> get props => [];
}

class ShippingMethodsInitial extends ShippingMethodsState {}

class ShippingMethodsLoading extends ShippingMethodsState {}

class ShippingMethodsLoaded extends ShippingMethodsState {
  const ShippingMethodsLoaded(this.methods);

  final List<ShippingMethodEntity> methods;

  @override
  List<Object?> get props => [methods];
}

class ShippingMethodsError extends ShippingMethodsState {
  const ShippingMethodsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
