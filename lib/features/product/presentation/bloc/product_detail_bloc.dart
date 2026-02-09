import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_product_by_id_usecase.dart';

part 'product_detail_event.dart';
part 'product_detail_state.dart';

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailBloc({
    required GetProductByIdUseCase getProductByIdUseCase,
  })  : _getProductByIdUseCase = getProductByIdUseCase,
        super(const ProductDetailInitial()) {
    on<ProductDetailLoadRequested>(_onLoad);
  }

  final GetProductByIdUseCase _getProductByIdUseCase;

  Future<void> _onLoad(
    ProductDetailLoadRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(const ProductDetailLoading());
    try {
      final product = await _getProductByIdUseCase(event.id);
      emit(ProductDetailLoaded(product));
    } catch (e) {
      emit(ProductDetailError(e.toString()));
    }
  }
}
