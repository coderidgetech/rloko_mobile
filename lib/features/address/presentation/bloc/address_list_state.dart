part of 'address_list_bloc.dart';

sealed class AddressListState extends Equatable {
  const AddressListState();
  @override
  List<Object?> get props => [];
}

final class AddressListInitial extends AddressListState {
  const AddressListInitial();
}

final class AddressListLoading extends AddressListState {
  const AddressListLoading();
}

final class AddressListLoaded extends AddressListState {
  const AddressListLoaded({required this.addresses});
  final List<AddressEntity> addresses;
  @override
  List<Object?> get props => [addresses.length];
}

final class AddressListError extends AddressListState {
  const AddressListError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
