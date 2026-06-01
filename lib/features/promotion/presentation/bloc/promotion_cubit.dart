import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/promotion_entity.dart';
import '../../domain/usecases/get_promotions_usecase.dart';
import '../../domain/usecases/validate_promotion_usecase.dart';

part 'promotion_state.dart';

class PromotionCubit extends Cubit<PromotionState> {
  PromotionCubit(this._getPromotions, this._validatePromotion)
      : super(PromotionInitial());

  final GetPromotionsUseCase _getPromotions;
  final ValidatePromotionUseCase _validatePromotion;

  Future<void> loadPromotions({bool activeOnly = false}) async {
    emit(PromotionLoading());
    try {
      final promotions = await _getPromotions.call(activeOnly: activeOnly);
      emit(PromotionLoaded(promotions));
    } catch (e) {
      emit(PromotionError(e.toString()));
    }
  }

  Future<void> validatePromotion(String code, {double subtotal = 0.0}) async {
    emit(PromotionLoading());
    try {
      await _validatePromotion.call(code, subtotal);
      // Re-emit loaded state if we had promotions before
      final current = state;
      if (current is PromotionLoaded) {
        emit(current);
      } else {
        emit(PromotionInitial());
      }
    } catch (e) {
      emit(PromotionError(e.toString()));
    }
  }
}
