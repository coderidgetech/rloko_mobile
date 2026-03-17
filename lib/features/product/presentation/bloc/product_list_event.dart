part of 'product_list_bloc.dart';

sealed class ProductListEvent extends Equatable {
  const ProductListEvent();

  @override
  List<Object?> get props => [];
}

final class ProductListLoadRequested extends ProductListEvent {
  const ProductListLoadRequested({
    this.limit,
    this.skip,
    this.category,
    this.gender,
    this.onSale,
    this.featured,
    this.gift,
    this.minPrice,
    this.maxPrice,
    this.sort,
  });

  final int? limit;
  final int? skip;
  final String? category;
  final String? gender;
  final bool? onSale;
  final bool? featured;
  final bool? gift;
  final double? minPrice;
  final double? maxPrice;
  final String? sort;

  @override
  List<Object?> get props =>
      [limit, skip, category, gender, onSale, featured, gift, minPrice, maxPrice, sort];
}

final class ProductListLoadFeatured extends ProductListEvent {
  const ProductListLoadFeatured({this.limit = 10});

  final int limit;

  @override
  List<Object?> get props => [limit];
}

final class ProductListLoadNewArrivals extends ProductListEvent {
  const ProductListLoadNewArrivals({this.limit = 10});

  final int limit;

  @override
  List<Object?> get props => [limit];
}

final class ProductListLoadOnSale extends ProductListEvent {
  const ProductListLoadOnSale({this.limit = 10});

  final int limit;

  @override
  List<Object?> get props => [limit];
}

final class ProductListLoadHomeSections extends ProductListEvent {
  const ProductListLoadHomeSections({this.limit = 10});

  final int limit;

  @override
  List<Object?> get props => [limit];
}
