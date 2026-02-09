part of 'category_list_bloc.dart';

sealed class CategoryListState extends Equatable {
  const CategoryListState();

  @override
  List<Object?> get props => [];
}

final class CategoryListInitial extends CategoryListState {
  const CategoryListInitial();
}

final class CategoryListLoading extends CategoryListState {
  const CategoryListLoading();
}

final class CategoryListLoaded extends CategoryListState {
  const CategoryListLoaded(this.categories);

  final List<CategoryEntity> categories;

  @override
  List<Object?> get props => [categories];
}

final class CategoryListError extends CategoryListState {
  const CategoryListError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
