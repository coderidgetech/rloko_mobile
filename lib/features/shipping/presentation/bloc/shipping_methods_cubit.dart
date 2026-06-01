import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/shipping_method_entity.dart';
import '../../domain/usecases/get_shipping_methods_usecase.dart';

part 'shipping_methods_state.dart';

class ShippingMethodsCubit extends Cubit<ShippingMethodsState> {
  ShippingMethodsCubit(this._getShippingMethods) : super(ShippingMethodsInitial());

  final GetShippingMethodsUseCase _getShippingMethods;

  Future<void> loadMethods({bool activeOnly = true}) async {
    emit(ShippingMethodsLoading());
    try {
      final methods = await _getShippingMethods.call(activeOnly: activeOnly);
      emit(ShippingMethodsLoaded(methods));
    } catch (e) {
      emit(ShippingMethodsError(e.toString()));
    }
  }
}
