part of 'address_list_bloc.dart';

sealed class AddressListEvent extends Equatable {
  const AddressListEvent();
  @override
  List<Object?> get props => [];
}

final class AddressListLoadRequested extends AddressListEvent {
  const AddressListLoadRequested();
}

final class AddressListDeleteRequested extends AddressListEvent {
  const AddressListDeleteRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

final class AddressListSetDefaultRequested extends AddressListEvent {
  const AddressListSetDefaultRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}
