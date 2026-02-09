import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/get_categories_usecase.dart';

part 'category_list_event.dart';
part 'category_list_state.dart';

class CategoryListBloc extends Bloc<CategoryListEvent, CategoryListState> {
  CategoryListBloc({
    required GetCategoriesUseCase getCategoriesUseCase,
  })  : _getCategoriesUseCase = getCategoriesUseCase,
        super(const CategoryListInitial()) {
    on<CategoryListLoadRequested>(_onLoad);
  }

  final GetCategoriesUseCase _getCategoriesUseCase;

  Future<void> _onLoad(
    CategoryListLoadRequested event,
    Emitter<CategoryListState> emit,
  ) async {
    emit(const CategoryListLoading());
    try {
      final list = await _getCategoriesUseCase();
      emit(CategoryListLoaded(list));
    } catch (e) {
      emit(CategoryListError(e.toString()));
    }
  }
}
