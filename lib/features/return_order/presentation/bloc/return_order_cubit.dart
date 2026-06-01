import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/return_entity.dart';
import '../../domain/usecases/create_return_usecase.dart';
import '../../domain/usecases/list_returns_usecase.dart';

part 'return_order_state.dart';

class ReturnOrderCubit extends Cubit<ReturnOrderState> {
  ReturnOrderCubit(this._listReturns, this._createReturn)
      : super(ReturnOrderInitial());

  final ListReturnsUseCase _listReturns;
  final CreateReturnUseCase _createReturn;

  Future<void> loadReturns({int limit = 20, int skip = 0}) async {
    emit(ReturnOrderLoading());
    try {
      final result = await _listReturns.call(limit: limit, skip: skip);
      emit(ReturnOrderLoaded(result.returns));
    } catch (e) {
      emit(ReturnOrderError(e.toString()));
    }
  }

  Future<void> createReturn({
    required String orderId,
    required List<Map<String, dynamic>> items,
    required String reason,
    String description = '',
  }) async {
    emit(ReturnOrderLoading());
    try {
      await _createReturn.call(
        orderId: orderId,
        items: items,
        reason: reason,
        description: description,
      );
      emit(ReturnOrderCreateSuccess());
    } catch (e) {
      emit(ReturnOrderError(e.toString()));
    }
  }
}
