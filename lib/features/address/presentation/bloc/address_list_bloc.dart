import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/address_entity.dart';
import '../../domain/usecases/address_usecases.dart';

part 'address_list_event.dart';
part 'address_list_state.dart';

class AddressListBloc extends Bloc<AddressListEvent, AddressListState> {
  AddressListBloc({
    required ListAddressesUseCase listAddressesUseCase,
    required DeleteAddressUseCase deleteAddressUseCase,
    required SetDefaultAddressUseCase setDefaultAddressUseCase,
  })  : _listAddressesUseCase = listAddressesUseCase,
        _deleteAddressUseCase = deleteAddressUseCase,
        _setDefaultAddressUseCase = setDefaultAddressUseCase,
        super(const AddressListInitial()) {
    on<AddressListLoadRequested>(_onLoad);
    on<AddressListDeleteRequested>(_onDelete);
    on<AddressListSetDefaultRequested>(_onSetDefault);
  }

  final ListAddressesUseCase _listAddressesUseCase;
  final DeleteAddressUseCase _deleteAddressUseCase;
  final SetDefaultAddressUseCase _setDefaultAddressUseCase;

  Future<void> _onLoad(
    AddressListLoadRequested event,
    Emitter<AddressListState> emit,
  ) async {
    emit(const AddressListLoading());
    try {
      final addresses = await _listAddressesUseCase();
      emit(AddressListLoaded(addresses: addresses));
    } catch (e) {
      final api = getApiException(e);
      if (api?.statusCode == 401) {
        emit(const AddressListError('Sign in to view your addresses'));
      } else {
        emit(AddressListError(api?.message ?? e.toString()));
      }
    }
  }

  Future<void> _onDelete(
    AddressListDeleteRequested event,
    Emitter<AddressListState> emit,
  ) async {
    final current = state;
    if (current is! AddressListLoaded) return;
    try {
      await _deleteAddressUseCase(event.id);
      final updated = current.addresses.where((a) => a.id != event.id).toList();
      emit(AddressListLoaded(addresses: updated));
    } catch (e) {
      emit(AddressListError(e.toString()));
    }
  }

  Future<void> _onSetDefault(
    AddressListSetDefaultRequested event,
    Emitter<AddressListState> emit,
  ) async {
    final current = state;
    if (current is! AddressListLoaded) return;
    try {
      await _setDefaultAddressUseCase(event.id);
      final updated = current.addresses
          .map((a) => AddressEntity(
                id: a.id,
                userId: a.userId,
                name: a.name,
                type: a.type,
                addressLine: a.addressLine,
                addressLine2: a.addressLine2,
                city: a.city,
                state: a.state,
                pincode: a.pincode,
                mobile: a.mobile,
                country: a.country,
                isDefault: a.id == event.id,
                createdAt: a.createdAt,
                updatedAt: a.updatedAt,
              ))
          .toList();
      emit(AddressListLoaded(addresses: updated));
    } catch (e) {
      emit(AddressListError(e.toString()));
    }
  }
}
